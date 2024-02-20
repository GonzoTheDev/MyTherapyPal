from flask import Flask, request, jsonify
from flask_cors import CORS 
from process_response import process_response
from waitress import serve

app = Flask(__name__)
CORS(app)

@app.route('/llm_api', methods=['POST'])
def llm_api():
    data = request.get_json()
    input_text = data['text']
    context = data['conversation_history']
    username = data['username']
    llm_response = process_response(username, input_text,  context)
    return jsonify({"llm_response": llm_response})

if __name__ == '__main__':
    serve(app, host='0.0.0.0', port=80)
    #app.run(port=5000)

