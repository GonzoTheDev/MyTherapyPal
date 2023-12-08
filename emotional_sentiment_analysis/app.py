from flask import Flask, request, jsonify
from flask_cors import CORS  # Import the CORS module
from predict import predict_emotion

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

@app.route('/predict', methods=['POST'])
def predict():
    data = request.get_json()
    input_text = data['text']
    predicted_emotion = predict_emotion(input_text)
    return jsonify({"predicted_emotion": predicted_emotion})

if __name__ == '__main__':
    app.run(port=5000)

