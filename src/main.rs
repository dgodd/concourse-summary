extern crate hyper;
extern crate rustc_serialize;
#[macro_use] extern crate nickel;

use nickel::{Nickel, HttpRouter, MediaType};
use std::io::Read;
use hyper::{Client};
use rustc_serialize::{json}; // Encodable,
use std::collections::HashMap;

fn get_content(url: &str) -> hyper::Result<String> {
    let client = Client::new();
    let mut response = try!(client.get(url).send());
    let mut buf = String::new();
    try!(response.read_to_string(&mut buf));
    Ok(buf)
}

#[derive(RustcDecodable, Debug)] // RustcEncodable,
struct Pipeline {
    name: String,
    url: String,
    paused: bool,
}
#[derive(RustcDecodable, Debug)]
struct Status {
    status: String,
}
#[derive(RustcDecodable, Debug)]
struct Job {
    name: String,
    groups: Vec<String>,
    next_build: Option<Status>,
    finished_build: Option<Status>,
}
#[derive(RustcEncodable, Debug)]
struct Data {
    pipeline: String,
    group: String,
    pipeline_url: String,
    running: bool,
    paused: bool,
    // statuses: HashMap<String, u32>,
}
impl Default for Data {
    fn default () -> Data {
        Data {
            pipeline: "".to_string(),
            group: "".to_string(),
            pipeline_url: "".to_string(),
            running: false, paused: false,
            // statuses: HashMap::<String, u32>::new(),
        }
    }
}

fn get_data(host: &str) -> Vec<Data> {
    let url = format!("https://{}/api/v1/pipelines" ,host);
    let result = get_content(&url);
    let pipelines: Vec<Pipeline> = json::decode(&(result.unwrap())).unwrap();
    let mut hashmap = HashMap::new();
    {
        for pipeline in pipelines {
            // println!("{:?}", pipeline);
            let url = format!("https://{}/api/v1{}/jobs" ,host, pipeline.url);
            let result = get_content(&url);
            let jobs: Vec<Job> = json::decode(&(result.unwrap())).unwrap();
            // println!("{:?}", jobs);
            for job in jobs {
                for group in job.groups {
                    // TODO handle empty groups
                    let datum = hashmap.entry(format!("{}:{:?}", pipeline.name, group)).or_insert_with(|| Data {
                        pipeline: format!("{}", pipeline.name),
                        group: format!("{}", group),
                        pipeline_url: format!("https://{}{}", host, pipeline.url),
                        paused: pipeline.paused,
                        ..Default::default()
                    });
                    if job.next_build.is_some() {
                        datum.running = true;
                    }
                }
            }
        }
    }
    // let vec: Vec<&Data> = Vec::new(); // &hashmap.iter().map(|(_x,y)| y).collect();
    let mut vec = Vec::new();
    for (_,item) in hashmap {
        vec.push(item);
    }
    return vec;
}

fn main() {
    let mut server = Nickel::new();

    server.get("/host/:host", middleware! { |req, mut res|
        if let Some(host) = req.param("host") {
            let out = get_data(&(host.replace(",",".")));
            if let Ok(out_json) = json::encode(&out) {
                res.set(MediaType::Json);
                out_json + "\n"
            } else { "WOOPS".to_string() }
        } else { "OOPS".to_string() }
    });
    server.get("**", middleware! { |_, response|
        "<h1>Call the police!</h1>"
    });
    server.get("/", middleware! { |_, response|
        "<h1>Call the fire brigade!</h1>"
    });

    server.listen("0.0.0.0:8080");
}
