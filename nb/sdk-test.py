# %%
from nemo_microservices import NeMoMicroservices

# Initialize the client
client = NeMoMicroservices(
    base_url="http://nemo.test",
    inference_base_url="http://nim.test"
)

# List namespaces
namespaces = client.namespaces.list()
print(namespaces.data)

# %%
import asyncio
from nemo_microservices import AsyncNeMoMicroservices

async def main():
    # Initialize the async client
    client = AsyncNeMoMicroservices(
        base_url="http://nemo.test",
        inference_base_url="http://nim.test"
    )
    
    # List namespaces
    namespaces = await client.namespaces.list()
    print(namespaces.data)

# Run the async function
asyncio.run(main())


