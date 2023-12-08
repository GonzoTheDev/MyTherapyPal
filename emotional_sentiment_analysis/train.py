import os
import pandas as pd
from transformers import AutoTokenizer, TFAutoModelForSequenceClassification
from sklearn.preprocessing import LabelEncoder
from sklearn.model_selection import train_test_split
import tensorflow as tf
import joblib  # Import joblib to save and load LabelEncoder

def train_model():
    # Load and preprocess the training data
    train_data = pd.read_csv("train.txt", sep=";", names=["text", "label"])

    # Encode labels
    label_encoder = LabelEncoder()
    train_data["label_encoded"] = label_encoder.fit_transform(train_data["label"])

    # Save the label encoder
    joblib.dump(label_encoder, 'label_encoder.joblib')

    # Split the data into training and validation sets
    train_set, valid_set = train_test_split(train_data, test_size=0.2, random_state=42)

    # Load tokenizer
    model_ckpt = "distilbert-base-uncased"
    tokenizer = AutoTokenizer.from_pretrained(model_ckpt)

    # Tokenize and prepare datasets
    def tokenize_data(data):
        tokens = tokenizer(data["text"].tolist(), padding=True, truncation=True, return_tensors="tf")
        return tokens

    train_tokens = tokenize_data(train_set)
    valid_tokens = tokenize_data(valid_set)

    # Prepare TF datasets
    batch_size = 16

    train_dataset = tf.data.Dataset.from_tensor_slices((dict(train_tokens), train_set["label_encoded"].tolist())).batch(batch_size)
    valid_dataset = tf.data.Dataset.from_tensor_slices((dict(valid_tokens), valid_set["label_encoded"].tolist())).batch(batch_size)

    # Load model architecture (not weights)
    model_ckpt = "distilbert-base-uncased"
    model = TFAutoModelForSequenceClassification.from_pretrained(model_ckpt, num_labels=len(label_encoder.classes_))

    # Compile and train the model
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=5e-5),
        loss=tf.keras.losses.SparseCategoricalCrossentropy(from_logits=True),
        metrics=tf.metrics.SparseCategoricalAccuracy()
    )

    model.fit(train_dataset, validation_data=valid_dataset, epochs=3)

    # Save the trained model
    model.save("emotion_model")
    print("Model trained and saved.")

# Check if the saved model exists
if not os.path.exists("emotion_model"):
    # Run the train_model function
    train_model()
    print("Model trained successfully.")
