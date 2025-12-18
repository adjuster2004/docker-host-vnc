#!/usr/bin/env python3
import os
import json
from datetime import datetime
from flask import Flask, render_template, request, jsonify, send_from_directory

app = Flask(__name__, static_folder='.', template_folder='.')

HOSTS_CUSTOM = "/data/hosts.custom"

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/style.css')
def style_css():
    return send_from_directory('.', 'style.css')

@app.route('/script.js')
def script_js():
    return send_from_directory('.', 'script.js')

@app.route('/api/hosts', methods=['GET'])
def api_get_hosts():
    try:
        if os.path.exists(HOSTS_CUSTOM):
            with open(HOSTS_CUSTOM, 'r') as f:
                content = f.read()
        else:
            content = "# Docker Hosts Manager\n\n"

        return jsonify({
            'success': True,
            'content': content
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/hosts', methods=['POST'])
def api_update_hosts():
    try:
        data = request.get_json()
        if not data or 'content' not in data:
            return jsonify({'success': False, 'error': 'No content'}), 400

        with open(HOSTS_CUSTOM, 'w') as f:
            f.write(data['content'])

        return jsonify({
            'success': True,
            'message': 'Hosts saved'
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/system/info', methods=['GET'])
def api_system_info():
    return jsonify({
        'success': True,
        'system': {
            'hostname': 'docker-hosts-manager',
            'vnc_password': 'admin123',
            'ports': {
                'web': 5000,
                'vnc': 5900,
                'web_vnc': 6080
            }
        }
    })

if __name__ == '__main__':
    print("Hosts Manager запущен: http://0.0.0.0:5000")
    app.run(host='0.0.0.0', port=5000, debug=False)
