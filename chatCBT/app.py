from flask import Flask, request, jsonify
from flask_cors import CORS
from process_response import process_response
from waitress import serve


app = Flask(__name__)

# Apply CORS to all routes and origins
CORS(app, resources={r"/llm_api": {"origins": "*"}}, supports_credentials=True)

@app.route('/llm_api', methods=['GET', 'POST', 'OPTIONS'])
def llm_api():
    # Handle OPTIONS request for preflight
    if request.method == 'OPTIONS':
        response = app.make_default_options_response()
    else:
        # Your existing POST logic
        data = request.get_json()
        input_text = data['text']
        context = data['conversation_history']
        username = data['username']
        llm_response = process_response(username, input_text, context)
        response = jsonify({"llm_response": llm_response})
    
    # Ensure CORS headers are added to the response
    headers = {
        'Access-Control-Allow-Origin': 'https://mytherapypal.ie',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type,Authorization',
        'Access-Control-Allow-Credentials': 'true'
    }
    if request.method == 'OPTIONS':
        for key, value in headers.items():
            response.headers.add(key, value)
    
    return response

if __name__ == '__main__':
    serve(app, host='0.0.0.0', port=5000, url_scheme='https')

