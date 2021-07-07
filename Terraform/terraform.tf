terraform {
  required_providers {
    aws = {
      source  = "aliyun/alicloud"
      version = "~> 1.125.0"
    }
  }
  backend "remote" {
    organization = "kingsun"

    workspaces {
      name = "devops"
    }
  }
}

provider "alicloud" {
  access_key = local.access_key
  secret_key = local.secret_key
  region     = "cn-shanghai"
}

resource "alicloud_instance" "instance" {
  availability_zone = "cn-shanghai-g"
  security_groups = ["sg-uf678653fp9gzvb3ctpw"]
  # series III
  instance_type        = "ecs.c5.xlarge"
  system_disk_category = "cloud_efficiency"
  image_id             = "centos_7_8_x64_20G_alibase_20200914.vhd"
  instance_name        = "test_foo"
  vswitch_id = "vsw-uf6xy8tcmfdczjyuiyh4n"
}
