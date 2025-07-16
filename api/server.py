#!/usr/bin/env python3
"""
AWS FinOps Tools API Server
Provides REST API endpoints for accessing cost data and reports
"""

import json
import os
import glob
import re
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Any

from flask import Flask, jsonify, request, send_file
from flask_cors import CORS

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Configuration
DATA_PATH = os.environ.get('DATA_PATH', '/app/data')
PORT = int(os.environ.get('PORT', 8081))

def get_latest_file(pattern: str, account: str = None) -> Optional[str]:
    """Find the most recent file matching the pattern"""
    if account:
        search_path = os.path.join(DATA_PATH, account, pattern)
    else:
        search_path = os.path.join(DATA_PATH, '**', pattern)
    
    files = glob.glob(search_path, recursive=True)
    if not files:
        return None
    
    # Sort by timestamp in filename
    files.sort(key=lambda x: re.search(r'(\d{8}_\d{6})', x).group(1) if re.search(r'(\d{8}_\d{6})', x) else '0')
    return files[-1]

def load_json_file(filepath: str) -> Optional[Dict]:
    """Load and parse JSON file"""
    try:
        with open(filepath, 'r') as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError) as e:
        print(f"Error loading {filepath}: {e}")
        return None

def get_file_info(filepath: str) -> Dict:
    """Get file metadata"""
    try:
        stat = os.stat(filepath)
        return {
            'name': os.path.basename(filepath),
            'size': stat.st_size,
            'modified': datetime.fromtimestamp(stat.st_mtime).isoformat(),
            'path': filepath
        }
    except OSError:
        return {}

@app.route('/api/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'data_path': DATA_PATH
    })

@app.route('/api/accounts', methods=['GET'])
def list_accounts():
    """List all available accounts"""
    try:
        accounts = []
        for item in os.listdir(DATA_PATH):
            account_path = os.path.join(DATA_PATH, item)
            if os.path.isdir(account_path):
                file_count = len(glob.glob(os.path.join(account_path, '*.json')))
                accounts.append({
                    'name': item,
                    'file_count': file_count,
                    'path': account_path
                })
        return jsonify({
            'accounts': accounts,
            'total': len(accounts)
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/files', methods=['GET'])
def list_files():
    """List all available data files"""
    try:
        account = request.args.get('account')
        file_type = request.args.get('type')
        
        files = []
        search_path = DATA_PATH
        
        if account:
            search_path = os.path.join(DATA_PATH, account)
        
        pattern = '*.json'
        if file_type:
            pattern = f'{file_type}_*.json'
        
        for filepath in glob.glob(os.path.join(search_path, '**', pattern), recursive=True):
            file_info = get_file_info(filepath)
            if file_info:
                file_info['account'] = os.path.basename(os.path.dirname(filepath))
                files.append(file_info)
        
        # Sort by modification time (newest first)
        files.sort(key=lambda x: x.get('modified', ''), reverse=True)
        
        return jsonify({
            'files': files,
            'total': len(files)
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/latest-data', methods=['GET'])
def get_latest_data():
    """Get the latest cost data for dashboard"""
    try:
        account = request.args.get('account', 'account1')
        
        # Get latest files
        daily_costs_file = get_latest_file('daily_costs_*.json', account)
        service_costs_file = get_latest_file('monthly_costs_by_service_*.json', account)
        region_costs_file = get_latest_file('costs_by_region_*.json', account)
        forecast_file = get_latest_file('cost_forecast_*.json', account)
        ri_file = get_latest_file('ri_utilization_*.json', account)
        
        data = {}
        
        if daily_costs_file:
            data['daily_costs'] = load_json_file(daily_costs_file)
        
        if service_costs_file:
            data['service_costs'] = load_json_file(service_costs_file)
        
        if region_costs_file:
            data['region_costs'] = load_json_file(region_costs_file)
        
        if forecast_file:
            data['forecast'] = load_json_file(forecast_file)
        
        if ri_file:
            data['ri_utilization'] = load_json_file(ri_file)
        
        return jsonify(data)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/cost-summary', methods=['GET'])
def get_cost_summary():
    """Get cost summary for all accounts"""
    try:
        summaries = []
        
        for account_dir in os.listdir(DATA_PATH):
            account_path = os.path.join(DATA_PATH, account_dir)
            if not os.path.isdir(account_path):
                continue
            
            # Get latest daily costs
            daily_costs_file = get_latest_file('daily_costs_*.json', account_dir)
            if daily_costs_file:
                daily_data = load_json_file(daily_costs_file)
                if daily_data and 'ResultsByTime' in daily_data:
                    total_cost = sum(
                        float(period['Total']['BlendedCost']['Amount'])
                        for period in daily_data['ResultsByTime']
                    )
                    summaries.append({
                        'account': account_dir,
                        'total_cost': total_cost,
                        'currency': daily_data['ResultsByTime'][0]['Total']['BlendedCost']['Unit'] if daily_data['ResultsByTime'] else 'USD',
                        'period_start': daily_data['ResultsByTime'][0]['TimePeriod']['Start'] if daily_data['ResultsByTime'] else None,
                        'period_end': daily_data['ResultsByTime'][-1]['TimePeriod']['End'] if daily_data['ResultsByTime'] else None
                    })
        
        return jsonify({
            'summaries': summaries,
            'total_accounts': len(summaries),
            'total_cost': sum(s['total_cost'] for s in summaries)
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/file/<account>/<filename>', methods=['GET'])
def get_file(account: str, filename: str):
    """Get a specific file"""
    try:
        filepath = os.path.join(DATA_PATH, account, filename)
        if not os.path.exists(filepath):
            return jsonify({'error': 'File not found'}), 404
        
        # Security check - ensure file is in the data directory
        if not os.path.realpath(filepath).startswith(os.path.realpath(DATA_PATH)):
            return jsonify({'error': 'Access denied'}), 403
        
        return send_file(filepath, mimetype='application/json')
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/metrics', methods=['GET'])
def get_metrics():
    """Get key metrics for dashboard"""
    try:
        account = request.args.get('account', 'account1')
        
        metrics = {
            'total_cost': 0,
            'forecasted_cost': 0,
            'ri_utilization': 0,
            'sp_utilization': 0,
            'cost_change': 0,
            'last_updated': None
        }
        
        # Get daily costs for total
        daily_costs_file = get_latest_file('daily_costs_*.json', account)
        if daily_costs_file:
            daily_data = load_json_file(daily_costs_file)
            if daily_data and 'ResultsByTime' in daily_data:
                metrics['total_cost'] = sum(
                    float(period['Total']['BlendedCost']['Amount'])
                    for period in daily_data['ResultsByTime']
                )
                metrics['last_updated'] = get_file_info(daily_costs_file).get('modified')
        
        # Get forecast
        forecast_file = get_latest_file('cost_forecast_*.json', account)
        if forecast_file:
            forecast_data = load_json_file(forecast_file)
            if forecast_data and 'Total' in forecast_data:
                metrics['forecasted_cost'] = float(forecast_data['Total']['Amount'])
        
        # Get RI utilization
        ri_file = get_latest_file('ri_utilization_*.json', account)
        if ri_file:
            ri_data = load_json_file(ri_file)
            if ri_data and 'Total' in ri_data:
                metrics['ri_utilization'] = float(ri_data['Total']['UtilizationPercentage'])
        
        return jsonify(metrics)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/search', methods=['GET'])
def search_files():
    """Search for files by pattern"""
    try:
        pattern = request.args.get('q', '')
        account = request.args.get('account')
        
        if not pattern:
            return jsonify({'error': 'Query parameter q is required'}), 400
        
        files = []
        search_path = DATA_PATH
        
        if account:
            search_path = os.path.join(DATA_PATH, account)
        
        for filepath in glob.glob(os.path.join(search_path, '**', f'*{pattern}*.json'), recursive=True):
            file_info = get_file_info(filepath)
            if file_info:
                file_info['account'] = os.path.basename(os.path.dirname(filepath))
                files.append(file_info)
        
        return jsonify({
            'files': files,
            'total': len(files),
            'query': pattern
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.errorhandler(404)
def not_found(error):
    return jsonify({'error': 'Endpoint not found'}), 404

@app.errorhandler(500)
def internal_error(error):
    return jsonify({'error': 'Internal server error'}), 500

if __name__ == '__main__':
    print(f"Starting AWS FinOps API Server on port {PORT}")
    print(f"Data path: {DATA_PATH}")
    
    # Check if data directory exists
    if not os.path.exists(DATA_PATH):
        print(f"Warning: Data directory {DATA_PATH} does not exist")
    
    app.run(host='0.0.0.0', port=PORT, debug=True)
