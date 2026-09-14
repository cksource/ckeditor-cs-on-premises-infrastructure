# The network, log group and storage bucket used to be declared directly in this
# module. They now come from the shared modules under `aws/modules`, which
# changes their addresses in the state. These blocks let Terraform move the
# existing resources instead of destroying and recreating them, so an existing
# deployment can be upgraded with a plain `terraform apply`.
#
# They are only needed by this module - the AI Service examples were published
# with the shared modules already in place.
moved {
  from = aws_vpc.vpc
  to   = module.network.aws_vpc.vpc
}

moved {
  from = aws_subnet.private
  to   = module.network.aws_subnet.private
}

moved {
  from = aws_subnet.public
  to   = module.network.aws_subnet.public
}

moved {
  from = aws_internet_gateway.gw
  to   = module.network.aws_internet_gateway.gw
}

moved {
  from = aws_route.internet_access
  to   = module.network.aws_route.internet_access
}

moved {
  from = aws_eip.gw
  to   = module.network.aws_eip.gw
}

moved {
  from = aws_nat_gateway.gw
  to   = module.network.aws_nat_gateway.gw
}

moved {
  from = aws_route_table.private
  to   = module.network.aws_route_table.private
}

moved {
  from = aws_route_table_association.private
  to   = module.network.aws_route_table_association.private
}

moved {
  from = aws_cloudwatch_log_group.log_group
  to   = module.logs.aws_cloudwatch_log_group.log_group
}

moved {
  from = aws_iam_role_policy.logs
  to   = module.logs.aws_iam_role_policy.logs
}

moved {
  from = random_string.id
  to   = module.storage.random_string.id
}

moved {
  from = aws_s3_bucket.storage
  to   = module.storage.aws_s3_bucket.storage
}

moved {
  from = aws_s3_bucket_public_access_block.storage
  to   = module.storage.aws_s3_bucket_public_access_block.storage
}

moved {
  from = aws_s3_bucket_server_side_encryption_configuration.storage
  to   = module.storage.aws_s3_bucket_server_side_encryption_configuration.storage
}
