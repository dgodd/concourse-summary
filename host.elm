import Html exposing (..)
import Html.App as App
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Lazy exposing (lazy, lazy2)
import Http
import Json.Decode as Json exposing ((:=), string, bool, object4)
import Task



main =
  App.program
    { init = init "capi.ci.cf-app.com"
    , view = view
    , update = update
    , subscriptions = subscriptions
    }



-- MODEL

type alias Status =
  { pipeline : String
  , group : String
  , paused : Bool
  , running : Bool
  }

type alias Model =
  { host : String
  , statuses : (List Status)
  }


init : String -> (Model, Cmd Msg)
init host =
  ( Model host []
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
      (Model model.host statuses, Cmd.none)

    FetchFail _ ->
      (model, Cmd.none)



-- VIEW

viewStatus : Status -> Html Msg
viewStatus status =
  div []
    [ h3 [] [text status.pipeline] ]


view : Model -> Html Msg
view model =
  div []
    [ h2 [] [text model.host]
    , button [ onClick MorePlease ] [ text "More Please!" ]
    , br [] []
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
      "http://localhost:3000/host/" ++ host
  in
    Task.perform FetchFail FetchSucceed (Http.get decodeStatuses url)


decodeStatuses : Json.Decoder (List Status)
decodeStatuses =
  Json.list (object4 Status
    ("pipeline" := string)
    ("group" := string)
    ("running" := bool)
    ("paused" := bool))
