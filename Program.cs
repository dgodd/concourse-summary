using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Threading.Tasks;
using Newtonsoft.Json;

class Program
{
  static void Main()
  {
    Task.Run(async () => {
      Console.WriteLine("Downloading page...");
      var pipelines = await DownloadPageAsync();
      foreach (var p in pipelines) {
        Console.WriteLine(p.Name + " :: " + p.URL + " :: " + (p.Paused ? "T": "F"));
      }
    }).Wait();
  }

  class Pipeline {
    public string Name { get; set; }
    public string URL { get; set; }
    public bool Paused { get; set; }
  }


  static async Task<List<Pipeline>> DownloadPageAsync()
  {
    string page = "https://ci.concourse.ci/api/v1/pipelines";
    using (HttpClient client = new HttpClient())
      using (HttpResponseMessage response = await client.GetAsync(page))
      using (HttpContent content = response.Content)
      {
        string result = await content.ReadAsStringAsync();
        if (result != null)
        {
          return JsonConvert.DeserializeObject<List<Pipeline>>(result);
        }
      }
    return new List<Pipeline>();
  }
}
