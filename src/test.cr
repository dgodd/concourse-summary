require "stumpy_png"
require "concourse-summary/job"

include StumpyPNG

    # <div class="aborted" style="width: <%= data.percent("aborted") %>%;"></div>
    # <div class="errored" style="width: <%= data.percent("errored") %>%;"></div>
    # <div class="failed" style="width: <%= data.percent("failed") %>%;"></div>
    # <div class="succeeded" style="width: <%= data.percent("succeeded") %>%;"></div>

canvas = Canvas.new(100, 50)

bg = RGBA.from_hex("#5C6C7D")
aborted = RGBA.from_hex("#8F4B2D")
errored = RGBA.from_hex("#E67E21")
failed = RGBA.from_hex("#E74C3C")
succeeded = RGBA.from_hex("#2ECC71")

url = "https://buildpacks.ci.cf-app.com/api/v1/teams/main/pipelines/python-buildpack/jobs"
client = HTTP::Client.get "https://buildpacks.ci.cf-app.com/"
Job.all(client, "teams/main/pipelines/python-buildpack")
Job
response.body_io

(0...100).each do |x|
  (0...50).each do |y|
    # RGBA.from_rgb_n(values, bit_depth) is an internal helper method
    # that creates an RGBA object from a rgb triplet with a given bit depth
    # color = RGBA.from_rgb_n(x, y, 255, 8)
    color = bg
    canvas[x, y] = color
  end
end

StumpyPNG.write(canvas, "rainbow.png")
