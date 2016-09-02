using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Newtonsoft.Json;

namespace WebApplication.Controllers
{
    [Route("host")]
    public class SummaryController : Controller
    {
        // [Route("/host/{host:string}")]
        [HttpGet("{host}")]
        public async Task<IActionResult> Host(string host)
        {
            // var host = "https://ci.concourse.ci/api/v1";
            // var host = "http://diego.ci.cf-app.com//api/v1";
            host = $"http://{host}/api/v1";

            var data = new Dictionary<string, MyData>();
            using (var client = new HttpClient())
            {
                var url = $"{host}/pipelines";
                var pipelines = await DownloadPipelines<List<Pipeline>>(client, url);
                foreach (var p in pipelines)
                {
                    // Console.WriteLine(p.Name + " :: " + $"{host}{p.URL}/jobs");
                    var jobs = await DownloadPipelines<List<Job>>(client, $"{host}{p.URL}/jobs");
                    foreach (var j in jobs)
                    {
                        // Console.WriteLine(j.Name + " :: " + (j.Running ? "R" : " ") + " :: " + j.Status);
                        foreach (var g in j.Groups)
                        {
                            // Console.WriteLine("       G: " + label);
                            Console.WriteLine($"{p.Name} : {g} : {j.Status}");

                            MyData datum;
                            if (!data.TryGetValue($"{p.Name}::{g}", out datum))
                            {
                                datum = new MyData()
                                {
                                    Labels = new string[] { p.Name, g }
                                };
                                data.Add($"{p.Name}::{g}", datum);
                            }
                            datum.IncStatus(j.Status);
                            // Console.WriteLine(JsonConvert.SerializeObject(datum));
                        }
                    }
                }
            }
            return Json(data.Values.ToList());
        }

        class Pipeline
        {
            public string Name { get; set; }
            public string URL { get; set; }
            public bool Paused { get; set; }
        }
        class Build
        {
            public string Status { get; set; }
        }
        class Job
        {
            public string Name { get; set; }
            [JsonProperty(PropertyName = "groups")]
            public string[] GroupNames { get; set; }
            [JsonProperty(PropertyName = "finished_build")]
            public Build FinishedBuild { private get; set; }
            [JsonProperty(PropertyName = "next_build")]
            public Build NextBuild { private get; set; }
            public bool Running { get { return NextBuild != null; } }
            public string Status { get { return FinishedBuild != null ? FinishedBuild.Status : "pending"; } }

            public IEnumerable<string> Groups
            {
                get
                {
                    if (GroupNames.Length > 0)
                    {
                        foreach (var group in GroupNames)
                        {
                            yield return group;
                        }
                    }
                    else
                    {
                        yield return "";
                    }
                }
            }
        }
        public class MyData
        {
            [JsonProperty(PropertyName = "labels")]
            public string[] Labels { get; set; }
            [JsonProperty(PropertyName = "pipeline_url")]
            public string PipelineURL { get; set; }
            [JsonProperty(PropertyName = "running")]
            public bool Running { get; set; }
            [JsonProperty(PropertyName = "paused")]
            public bool Paused { get; set; }
            [JsonProperty(PropertyName = "statuses")]
            public ConcurrentDictionary<string, int> Statuses { get; set; }

            public MyData()
            {
                Statuses = new ConcurrentDictionary<string, int>();
            }

            public void IncStatus(string status)
            {
                Statuses.AddOrUpdate(status, 1, (id, count) => count + 1);
            }
        }

        static async Task<T> DownloadPipelines<T>(HttpClient client, string page) where T : new()
        {
            using (var response = await client.GetAsync(page))
            using (var content = response.Content)
            {
                string result = await content.ReadAsStringAsync();
                if (result != null)
                {
                    return JsonConvert.DeserializeObject<T>(result);
                }
            }
            return new T();
        }
    }
}