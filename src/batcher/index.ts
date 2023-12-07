import { CloudEvent, CloudEventV1, CloudEventV1Attributes } from "cloudevents";
import { DaprServer, CommunicationProtocolEnum } from "@dapr/dapr";
import { LoremIpsum } from "lorem-ipsum";
import { nanoid } from "nanoid";

const daprHost = "127.0.0.1";
const appHost: string = "127.0.0.1";
const appPort = process.env.APP_PORT ?? "3000";
const daprPort = process.env.DAPR_HTTP_PORT;


async function start() {
	const pubSubName = "pubsub";
	const topic = "input-batches";

	const lorem = new LoremIpsum({
		sentencesPerParagraph: {
			max: 8,
			min: 4,
		},
		wordsPerSentence: {
			max: 16,
			min: 4,
		},
	});
	const server = new DaprServer({
		serverHost: appHost,
		serverPort: appPort,
		communicationProtocol: CommunicationProtocolEnum.HTTP,
		clientOptions: {
			daprHost,
			daprPort,
		},
	});
	await server.binding.receive("batcher-cron", async () => {
		console.log(`batcher-cron triggered!`);

		// Publish message to topic as application/json
		// Generate message with text separated by newlines
		const id = nanoid(5);
		const message = lorem.generateParagraphs(5);
		const response = await server.client.pubsub.publish(pubSubName, topic, {
			id,
			data: message,
		});
		if (response.error) {
			console.log("Error publishing message: " + response.error);
		} else{
			console.log(`Published message (${id})`);
		}
	});
	await server.start();
}

start().catch((e) => {
	console.error(e);
	process.exit(1);
});
