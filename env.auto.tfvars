name              = "mbm"
mms_load_balancer = false
nodes             = [
  {
    count            = 3,
    name             = "rs",
    groups           = ["agent"]
    mms_project      = "project1"
    instance_type    = "t3.small",
    data_volume_size = 50,
  },
  {
    count            = 1,
    name             = "mms",
    groups           = ["webapp", "appdb"]
    instance_type    = "t3.large",
    root_volume_size = 50,
    data_volume_size = 50,
  }
]