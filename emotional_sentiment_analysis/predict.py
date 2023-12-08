import os
import joblib
import tensorflow as tf
from transformers import AutoTokenizer
from train import train_model 
import argparse

# Check if the saved model exists
if not os.path.exists("emotion_model"):
    # Run the train script to train the model
    train_model()
    print("Model trained successfully.")

# Load the trained model
model = tf.keras.models.load_model("emotion_model")

# Load tokenizer
model_ckpt = "distilbert-base-uncased"
tokenizer = AutoTokenizer.from_pretrained(model_ckpt)

# Load label encoder
label_encoder = joblib.load('label_encoder.joblib')

def predict_emotion(input_text):
    tokens = tokenizer(input_text, padding=True, truncation=True, return_tensors="tf")
    inputs = {
        'input_ids': tokens['input_ids'],
        'attention_mask': tokens['attention_mask']
    }

    # Make prediction
    predictions = model.predict(inputs)
    
    # Extract logits from the predictions dictionary
    logits = predictions['logits']
    
    # Determine the predicted label
    predicted_label = int(tf.argmax(logits, axis=-1)[0])
    
    # Convert the predicted label to emotion
    predicted_emotion = label_encoder.inverse_transform([predicted_label])[0]
    
    return predicted_emotion

# Create an argument parser
parser = argparse.ArgumentParser()
parser.add_argument("--text", type=str, help="Input text for emotion prediction")

# Parse the command line arguments
args = parser.parse_args()

# Get the input text from the command line
input_text = args.text if args.text else "No input text provided"


# Make prediction
predicted_emotion = predict_emotion(input_text)

# Print the input text
print(f"The input text is: {input_text}")
# Print the result
print(f"The predicted emotion is: {predicted_emotion}")
