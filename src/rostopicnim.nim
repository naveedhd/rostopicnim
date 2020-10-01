import httpClient
import xmltree
import xmlparser
import os
import strutils

type
  TopicInfo = tuple
    name: string
    providers: seq[string]

  SystemState = array[3, seq[TopicInfo]]

  SystemStateResponse = tuple
    code: int
    message: string
    value: SystemState

# xmlrpc.ServerProxy
proc get_system_state(uri, method_name, param: string): SystemStateResponse =
  let client = newHttpClient()
  client.headers = newHttpHeaders( {"Content-Type": "text/xml"} )

  var method_name_xml = newElement("methodName")
  method_name_xml.add newText(method_name)

  var value_xml = newElement("value")
  value_xml.add newText(param)

  var params_xml = newElement("params")
  params_xml.add value_xml

  let body = newXmlTree("methodCall", [method_name_xml, params_xml])

  # let body = """
  # <methodCall>
  #   <methodName>getSystemState</methodName>
  #   <params><value>caller_id</value></params>
  # </methodCall>
  # """

  var code: int
  var message: string
  try:
    let response = client.postContent(uri & "/RPC2", body = $body)
    let response_xml = parseXml(response)
    let data_xml = response_xml.child("params")
                   .child("param")
                   .child("value")
                   .child("array")
                   .child("data")

    code = data_xml[0].innerText.parseInt
    message = data_xml[1].innerText

    # TODO: need consistent parsing
    echo data_xml[2]

    for value_xml in data_xml:
      if value_xml[0].tag == "array":
        for val in value_xml[0].child("data"):
          echo val.innerText
  except OSError:
    echo "OS Error!"

  client.close()

  var publishers_info: seq[TopicInfo]
  # publishers_info.add((name: "foo", providers: newSeq[string](0)))
  # publishers_info[0] = (name: "foo", providers: newSeq[string](0))

  var subcribers_info: seq[TopicInfo]
  # subcribers_info[0] = (name: "foo", providers: newSeq[string](0))

  var services_info: seq[TopicInfo]
  # services_info[0] = (name: "foo", providers: newSeq[string](0))

  let value: array[3, seq[TopicInfo]] = [publishers_info, subcribers_info, services_info]

  let system_state: SystemStateResponse = (code: code, message: message, value: value)
  system_state

# rosgraph.rosenv
proc get_master_uri(): string =
  let ros_master_uri = "ROS_MASTER_URI"
  if os.existsEnv(ros_master_uri):
    os.getEnv(ros_master_uri)
  else:
    "http://localhost:11311"


# rosgraph.masterapi
proc succeed(response: SystemStateResponse): SystemState =
  if response.code == 1:
    response.value
  else:
    raise

proc get_system_state(caller_id: string) =
  let master_uri = get_master_uri()
  let system_state = get_system_state(master_uri, "getSystemState", caller_id)
  let success = succeed(system_state)
  echo success


# rostopic.__init__
proc get_topic_list() =
  get_system_state("/rostopic")


proc rostopic_list(topic: string) =
  get_topic_list()


when isMainModule:
  rostopic_list("/foo")
