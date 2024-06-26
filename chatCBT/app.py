from flask import Flask, request, jsonify
from flask_cors import CORS, cross_origin
from process_response import generate_rsa_keypair, process_response, summarize_notes
from waitress import serve


app = Flask(__name__)

# Variable to enable or disable CORS
ENABLE_CORS = True

if ENABLE_CORS:
    # Apply CORS to all routes and origins if ENABLE_CORS is True
    CORS(app, resources={r"/*": {"origins": "*"}}, supports_credentials=True)

@app.route('/llm_api', methods=['GET', 'POST', 'OPTIONS'])
def llm_api():
    print("Request received")
    if request.method == 'OPTIONS':
        response = app.make_default_options_response()
    else:
        data = request.get_json()
        context = data['conversation_history']
        username = data['username']
        llm_response = process_response(username, context)
        response = jsonify({"llm_response": llm_response})
    
    # Manually setting CORS headers (consider removing if using flask_cors for simplicity)
    if ENABLE_CORS:
        headers = {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type,Authorization',
            'Access-Control-Allow-Credentials': 'true'
        }
        if request.method == 'OPTIONS':
            for key, value in headers.items():
                response.headers.add(key, value)
    
    return response

@app.route('/summary_api', methods=['GET', 'POST', 'OPTIONS'])
def summary_api():
    if request.method == 'OPTIONS':
        response = app.make_default_options_response()
    else:
        data = request.get_json()
        response = summarize_notes(data)
        #response = jsonify({"summary_response": summaryResponse})
    
    # Manually setting CORS headers (consider removing if using flask_cors for simplicity)
    if ENABLE_CORS:
        headers = {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type,Authorization',
            'Access-Control-Allow-Credentials': 'true'
        }
        if request.method == 'OPTIONS':
            for key, value in headers.items():
                response.headers.add(key, value)
    
    return response

@app.route('/generate_rsa_keys', methods=['POST'])
def generate_rsa_keys_api():
    pem_private_key, pem_public_key = generate_rsa_keypair()
    return jsonify({
        "publicKey": pem_public_key.decode('utf-8'),
        "privateKey": pem_private_key.decode('utf-8')
    })


if __name__ == '__main__':
    ENABLE_CORS = True
    if ENABLE_CORS:
        serve(app, host='0.0.0.0', port=5000, url_scheme='https')
    else:
        serve(app, host='0.0.0.0', port=5000)
