import Html exposing (..)
import Html.App as App
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Lazy exposing (lazy, lazy2)
import Http
import Json.Decode as Json exposing ((:=), int, string, bool, dict)
import Task
import Dict
import Maybe exposing (withDefault)
import Debug exposing (log)


main =
  App.program
    { init = init "buildpacks.ci.cf-app.com"
    , view = view
    , update = update
    , subscriptions = subscriptions
    }



-- MODEL

type alias Status =
  { pipeline : String
  , group : Maybe String
  , paused : Bool
  , running : Bool
  , statuses : Dict.Dict String Int
  }

type alias Model =
  { host : String
  , error : String
  , statuses : (List Status)
  }


init : String -> (Model, Cmd Msg)
init host =
  ( Model host "" []
  , getHostStatuses host
  )



-- UPDATE


type Msg
  = MorePlease
  | FetchSucceed (List Status)
  | FetchFail Http.Error


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    MorePlease ->
      (model, getHostStatuses model.host)

    FetchSucceed statuses ->
        let
          mkPercent : Status -> Status
          mkPercent = (\status ->
            let
              total = log "total" (toFloat (List.sum (Dict.values status.statuses)))
              newStatuses = log "newStatuses" (Dict.map (\_ v -> floor ((toFloat v) * 100.0 / total)) status.statuses)
              newStatus = {status | statuses = newStatuses}
            in
              newStatus)
          statuses2 = (log "statuses" (List.map mkPercent statuses))
      in
        (Model model.host "" statuses2, Cmd.none)

    FetchFail x ->
      (Model model.host (toString x) [], Cmd.none)



-- VIEW


viewStatus : Status -> Html Msg
viewStatus status =
  let
    single name =
      div [ class name, style [("width", toString (withDefault 0 (Dict.get name status.statuses)) ++ "%")] ] []
  in
    a [ href "https://<%= host %><%= data.href %>", target "_blank", class "outer" ]
      [ div [ class "status" ] <| List.map single ["aborted","errored","failed","succeeded"]
      , div [ class "inner" ]
          [ div [] [ text status.pipeline ]
          , div [] [ text (withDefault "" status.group) ]
          ]
      ]


view : Model -> Html Msg
view model =
  div []
    [
      div [ class "time" ] [ text "Concourse Summary" ]
    , div [ class "error" ] [ text model.error ]
    , div [] <| List.map viewStatus model.statuses
    ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none



-- HTTP


getHostStatuses : String -> Cmd Msg
getHostStatuses host =
  let
    url =
      -- "http://localhost:3000/host/" ++ host
      "/hosta.json"
  in
    Task.perform FetchFail FetchSucceed (Http.get decodeStatusList url)

decodeStatusList : Json.Decoder (List Status)
decodeStatusList =
  Json.list (Json.object5 Status
    ("pipeline" := string)
    ("group" := Json.maybe string)
    ("running" := bool)
    ("paused" := bool)
    ("statuses" := dict int))
