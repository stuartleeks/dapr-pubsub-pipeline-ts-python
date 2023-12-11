#!/bin/bash
set -e

#
# This script expects to find an output.json in the infra folder with the values
# from the infrastructure deployment.
# It then creates the env files etc for each component
#

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

output_file="$script_dir/../infra/output.json"

if [[ -f "$script_dir/../.env" ]]; then
	source "$script_dir/../.env"
fi

service_bus_namespace_name=$(jq -r '.service_bus_namespace_name' < "$output_file")
if [[ ${#service_bus_namespace_name} -eq 0 ]]; then
  echo 'ERROR: Missing output value service_bus_namespace_name' 1>&2
  exit 6
fi
service_bus_connection_string=$(az servicebus namespace authorization-rule keys list --resource-group $RESOURCE_GROUP --namespace-name $service_bus_namespace_name --name RootManageSharedAccessKey --query primaryConnectionString -o tsv)

service_bus_namespace_qualified_name=$(jq -r '.service_bus_namespace_qualified_name' < "$output_file")
if [[ ${#service_bus_namespace_qualified_name} -eq 0 ]]; then
  echo 'ERROR: Missing output value service_bus_namespace_qualified_name' 1>&2
  exit 6
fi

batcher_client_id=$(jq -r '.batcher_client_id' < "$output_file")
if [[ ${#batcher_client_id} -eq 0 ]]; then
  echo 'ERROR: Missing output value batcher_client_id' 1>&2
  exit 6
fi
batch_receiver_client_id=$(jq -r '.batch_receiver_client_id' < "$output_file")
if [[ ${#batch_receiver_client_id} -eq 0 ]]; then
  echo 'ERROR: Missing output value batch_receiver_client_id' 1>&2
  exit 6
fi
message_processor_client_id=$(jq -r '.message_processor_client_id' < "$output_file")
if [[ ${#message_processor_client_id} -eq 0 ]]; then
  echo 'ERROR: Missing output value message_processor_client_id' 1>&2
  exit 6
fi

#create secret file with connection string for pubsub
cat <<EOF > "$script_dir/../components-k8s/pubsub.secret.yaml"
apiVersion: v1
data:
   namespaceName: $(echo -n "$service_bus_namespace_qualified_name" | base64 -w 0)
kind: Secret
metadata:
  name: servicebus-pubsub-secret
  namespace: default
type: Opaque
EOF
echo "CREATED: k8s secret file"



cat <<EOF > "$script_dir/../src/batcher/secrets.json"
{
  "SERVICE_BUS_CONNECTION_STRING": "$service_bus_connection_string"
}
EOF
echo "CREATED: local secret file for batcher"

cat <<EOF > "$script_dir/../src/batch_receiver/secrets.json"
{
  "SERVICE_BUS_CONNECTION_STRING": "$service_bus_connection_string"
}
EOF
echo "CREATED: local secret file for batch_receiver"

cat <<EOF > "$script_dir/../src/message_processor/secrets.json"
{
  "SERVICE_BUS_CONNECTION_STRING": "$service_bus_connection_string"
}
EOF
echo "CREATED: local secret file for message_processor"


service_account_namespace="default"
service_account_name="batcher"
client_id=$batcher_client_id
cat <<EOF > "$script_dir/../components-k8s/serviceaccount-${service_account_name}.secret.yaml"
apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    azure.workload.identity/client-id: ${client_id}
  labels:
    azure.workload.identity/use: "true"
  name: ${service_account_name}
  namespace: ${service_account_namespace}
EOF
echo "CREATED: k8s service account file for $service_account_name"


service_account_namespace="default"
service_account_name="batch-receiver"
client_id=$batch_receiver_client_id
cat <<EOF > "$script_dir/../components-k8s/serviceaccount-${service_account_name}.secret.yaml"
apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    azure.workload.identity/client-id: ${client_id}
  labels:
    azure.workload.identity/use: "true"
  name: ${service_account_name}
  namespace: ${service_account_namespace}
EOF
echo "CREATED: k8s service account file for $service_account_name"

service_account_namespace="default"
service_account_name="message-processor"
client_id=$message_processor_client_id
cat <<EOF > "$script_dir/../components-k8s/serviceaccount-${service_account_name}.secret.yaml"
apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    azure.workload.identity/client-id: ${client_id}
  labels:
    azure.workload.identity/use: "true"
  name: ${service_account_name}
  namespace: ${service_account_namespace}
EOF
echo "CREATED: k8s service account file for $service_account_name"
