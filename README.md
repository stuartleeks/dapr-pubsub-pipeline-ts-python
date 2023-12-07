# dapr-pubsub-pipeline-ts-python

Example of a Dapr pubsub pipeline with TypeScript and Python

- [dapr-pubsub-pipeline-ts-python](#dapr-pubsub-pipeline-ts-python)
	- [Overview](#overview)
	- [Running the project](#running-the-project)
	- [Cleaning up Dapr logs](#cleaning-up-dapr-logs)
	- [Running in Kubernetes](#running-in-kubernetes)


## Overview

The project is made up of a number of services as shown in the following diagram:

```
              message                          individual
               batch                           messages
┌─────────┐               ┌────────────────┐                 ┌────────────────────┐
│         │               │                │                 │                    │
│ batcher ├──────────────►│ batch_receiver ├────────────────►│ message_processor  │          ... further
│         │               │                │                 │                    │          processing here
└─────────┘               └────────────────┘                 └──┬─────────────────┘
                                                                │
                                                                │ HTTP API
                                                                │ (rate-limited)
                                                                │
                                                                ▼
                                                             ┌────────────────────┐
                                                             │                    │
                                                             │ processing_service │
                                                             │                    │
                                                             └────────────────────┘
```

| Service            | Language   | Description                                                                                                        |
| ------------------ | ---------- | ------------------------------------------------------------------------------------------------------------------ |
| batcher            | TypeScript | Simulates periodic retrieval of message content for processing and puts the content onto the `input-batches` queue |
| batch_receiver     | Python     | Receives batches of messages from the `input-batches` queue and splits them before sending to the `messages` queue |
| message_processor  | Python     | Receives individual messages from the `messages` queue and processes them using the `processing_service`           |
| processing_service | Python     | A rate-limited HTTP API that simulates doing work                                                                  |

## Running the project

The easiest way to run the project is to load it in Visual Studio Code using the Dev Containers extension as this automatically sets up the environment for you.

Once open as a dev container:
1. Run `dapr init` to initialise Dapr
2. Run `dapr run -f ./dapr.yaml` to start the services
3. ... TODO: how to view the results

## Cleaning up Dapr logs

When running, logs for each service are written to a `.dapr` folder under each service folder.
These can be cleaned up by running `find . -name ".dapr" | rm -rf` from the root of the project.

## Running in Kubernetes

TODO: deploy to K8s




