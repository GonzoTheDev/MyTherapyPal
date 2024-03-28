from flask import jsonify
from transformers import LlamaTokenizer, pipeline
from auto_gptq import AutoGPTQForCausalLM, BaseQuantizeConfig
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives import serialization

# Set the quantization configuration
quantize_config = BaseQuantizeConfig(**{"bits": 4, "damp_percent": 0.01, "desc_act": True, "group_size": 128})

# Set the model id
model_id = 'TheBloke/Llama-2-13B-chat-GPTQ'

# Load the model
m = AutoGPTQForCausalLM.from_quantized(model_id,  device="cuda:0", quantize_config=quantize_config, use_safetensors=True)

# Load the tokenizer
t = LlamaTokenizer.from_pretrained(
    pretrained_model_name_or_path=model_id,
)

# Create the pipeline
pipe = pipeline(
    "text-generation",
    model=m,
    tokenizer=t,
    batch_size=1,
    max_length=4096,
    repetition_penalty=1.2
)

# Create the pipeline
summary_pipe = pipeline(
    "text-generation",
    model=m,
    tokenizer=t,
    batch_size=1,
    max_length=4096,
    repetition_penalty=1.2
)

# Function that takes the user prompt and conversation history (which includes context/task assignment) and returns the ai assistant response
def process_response(username, user_prompt, conversation_history):
    labeled_history = [f"{username if i % 2 == 0 else 'Assistant'}: {msg}" for i, msg in enumerate(conversation_history)]
    prompt_with_context = "\n".join(labeled_history + [f"Assistant:"])
    
    print(f"Prompt with context: {prompt_with_context}")
    
    # Get generated text and strip the prompt
    generated_text = pipe(prompt_with_context)[0]['generated_text']

    print(f"Generated text: {generated_text}")

    assistant_response = generated_text.split("Assistant:")[-1].strip()

    print(f"Assistant response: {assistant_response}")

    return assistant_response


# Function that takes the user prompt and conversation history (which includes context/task assignment) and returns the ai assistant response
def summarize_notes(data):
     # Start with a clear context
    context = "Below are the user's mental health notes from the past week. Please summarize the key points for therapeutic review:"
    
    # Prepare the input text for the model
    formatted_notes = [f"Title: {note['title']}\nNote: {note['text']}\nTimestamp: {note['timestamp']}" for note in data]
    notes_with_context = "\n\n".join(formatted_notes)
    
    # Add an explicit request for summary at the end
    summary_request = "\n\nSummary: Please provide a summary of the key points for the therapist."
    
    prompt_for_model = context + "\n\n" + notes_with_context + summary_request
    
    # Generate summary using the pipeline, with adjusted parameters for focused summarization
    summary_output = summary_pipe(prompt_for_model, max_length=1000, min_length=100, length_penalty=2.0, num_return_sequences=1, temperature=0.7, top_p=0.9)

    # Extracting the summary text from the output
    summary_text = summary_output[0]['generated_text']
    
    # If the model still includes the original prompt in the output, you might need to trim it
    therapist_summary = summary_text.split("Summary: Please provide a summary of the key points for the therapist.")[1].strip() if "Summary: Please provide a summary of the key points for the therapist." in summary_text else summary_text
    
    client_summary = rephrase_for_client(therapist_summary)

    final_result = jsonify({"summary_response": {"therapist_summary": therapist_summary, "client_summary": client_summary}})

    return final_result

def rephrase_for_client(response):
    # Rephrase the response for the client
    request = "Task: Rephrase the above response as if you are talking directly to the user: "
    prompt =  response +  "\n\n" + request
    rephrased_response = summary_pipe(prompt, max_length=1000, min_length=100, length_penalty=2.0, num_return_sequences=1, temperature=0.7, top_p=0.9)
    response_text = rephrased_response[0]['generated_text']
    final_response = response_text.split("Task: Rephrase the above response as if you are talking directly to the user: ")[1].strip()
    return final_response


def generate_rsa_keypair():
    # Generate a private key
    private_key = rsa.generate_private_key(
        public_exponent=65537,
        key_size=4096,
        backend=default_backend()
    )
    # Generate a public key
    public_key = private_key.public_key()

    # Serialize the private key to PEM format
    pem_private_key = private_key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption()
    )

    # Serialize the public key to PEM format
    pem_public_key = public_key.public_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PublicFormat.SubjectPublicKeyInfo
    )

    return pem_private_key, pem_public_key