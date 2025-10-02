variable "test_var" {
  type = string
}

resource "null_resource" "test" {
  triggers = {
    name = var.test_var
  }

  provisioner "local-exec" {
    when        = create
    command     = "Write-Output \"Hello ${var.test_var}\""
    interpreter = ["pwsh", "-Command"]
  }
}
