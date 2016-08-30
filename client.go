package main

import (
	"fmt"
	"log"
	"net/http"
	"time"

	"encoding/json"

	"github.com/gorilla/mux"
)

type Pipeline struct {
	Name   string
	Url    string
	Paused bool
}
type Status struct {
	Status string
}
type Job struct {
	Name          string
	Groups        []string
	NextBuild     *Status `json:"next_build"`
	FinishedBuild *Status `json:"finished_build"`
}
type Data struct {
	Pipeline string
	Group    string
	Url      string `json:"pipeline_url"`
	Running  bool
	Paused   bool
	Statuses map[string]int
}

func getJson(httpClient *http.Client, url string, target interface{}) error {
	r, err := httpClient.Get(url)
	if err != nil {
		return err
	}
	defer r.Body.Close()

	return json.NewDecoder(r.Body).Decode(target)
}

func createHTTPClient() *http.Client {
	client := &http.Client{
		Transport: &http.Transport{
			MaxIdleConnsPerHost: 2,
		},
		Timeout: time.Duration(5) * time.Second,
	}

	return client
}

func getData(host string) ([]Data, error) {
	httpClient := createHTTPClient()
	var pipelines []Pipeline
	err := getJson(httpClient, fmt.Sprintf("%s/api/v1/pipelines", host), &pipelines)
	if err != nil {
		return []Data{}, err
	}
	data := map[string]Data{}
	for _, pipeline := range pipelines {
		var jobs []Job
		err := getJson(httpClient, fmt.Sprintf("%s/api/v1%s/jobs", host, pipeline.Url), &jobs)
		if err != nil {
			return []Data{}, err
		}
		for _, job := range jobs {
			groups := job.Groups
			if len(groups) == 0 {
				groups = []string{""}
			}
			for _, group := range groups {
				key := fmt.Sprintf("%s:%s", pipeline.Name, group)
				datum := data[key]
				if datum.Statuses == nil {
					datum.Statuses = map[string]int{}
					datum.Pipeline = pipeline.Name
					datum.Group = group
					datum.Paused = pipeline.Paused
					datum.Url = fmt.Sprintf("%s%s", host, pipeline.Url)
				}
				if !datum.Running {
					datum.Running = (job.NextBuild != nil)
				}
				if job.FinishedBuild != nil {
					datum.Statuses[job.FinishedBuild.Status] += 1
				} else {
					datum.Statuses["pending"] += 1
				}
				data[key] = datum
			}
		}
	}
	values := make([]Data, 0, len(data))
	for _, value := range data {
		values = append(values, value)
	}

	return values, nil
}

func HostIndex(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	host := vars["host"]
	values, err := getData(fmt.Sprintf("https://%s", host))
	if err != nil {
		panic(err.Error())
	}
	json.NewEncoder(w).Encode(values)
}

func main() {
	router := mux.NewRouter().StrictSlash(true)
	router.HandleFunc("/host/{host}", HostIndex)
	fmt.Println("listening on :8080")
	log.Fatal(http.ListenAndServe(":8080", router))

	// values, err := getData("https://buildpacks.ci.cf-app.com")
	// if err != nil {
	// 	panic(err.Error())
	// }
	// fmt.Printf("%#v\n", values)
}
