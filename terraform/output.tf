output "jenkins_public_ip" {
  value = aws_instance.jenkins.public_ip
}

output "k8s_node_public_ip" {
  value = aws_instance.k8s_node.public_ip
}
