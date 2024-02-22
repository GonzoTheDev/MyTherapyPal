from transformers import LlamaTokenizer, pipeline
from auto_gptq import AutoGPTQForCausalLM, BaseQuantizeConfig

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
    #temperature=0.6,
    #top_p=0.95,
    repetition_penalty=1.2
)

# Function that takes the user prompt and conversation history (which includes context/task assignment) and returns the ai assistant response
def process_response(username, user_prompt, conversation_history):
    labeled_history = [f"{username if i % 2 == 0 else 'Assistant'}: {msg}" for i, msg in enumerate(conversation_history)]
    prompt_with_context = "\n".join(labeled_history + [f"Assistant:"])
    
    print(f"Prompt with context: {prompt_with_context}")
    
    # Assuming `pipe` is your model's prediction function
    generated_text = pipe(prompt_with_context)[0]['generated_text']
    assistant_response = generated_text.split("Assistant:")[-1].strip()
    return assistant_response
