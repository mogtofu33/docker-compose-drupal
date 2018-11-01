import os
import docker
import requests
import json
from apacheconfig import *
from flask import Flask, jsonify, render_template, g, request, redirect, url_for
from dotenv import load_dotenv
# from pprint import pprint
# from flask_debug import Debug

app = Flask(__name__)
app.jinja_env.add_extension('jinja2.ext.do')
app.jinja_env.lstrip_blocks = True
app.jinja_env.trim_blocks = True

client = docker.from_env()

data = {}

with open('/app/config.json', 'r') as f:
    config = json.load(f)

def get_vhost():
    if os.path.isfile(config['env']['vhost']):
        with make_loader() as loader:
            vhost = loader.load(config['env']['vhost'])
            return vhost.get('VirtualHost')

def get_nginx():
    result = {}
    with open(config['env']['nginx'], "r") as fp:
        for line in lines_that_contain("/var/www/localhost", fp):
            result["root"] = line.replace('root ', '').strip()[:-1]
    for container in client.containers.list():
        if container.id == 'dcd-nginx':
            container = client.containers.get('dcd-nginx')
            envs = container.attrs['Config']['Env']
            for env in envs:
                val = env.split('=')
                result[val[0]] = val[1]
    return result

def get_tools():
    result = {}
    if os.path.exists(config['env']['tools']):
        for item in os.listdir(config['env']['tools']):
            if os.path.isfile(os.path.join(config['env']['tools'], item)):
                if item.endswith(".php"):
                    name = item.replace(".php", "")
                    result[name] = item
            elif os.path.isdir(os.path.join(config['env']['tools'], item)):
                result[item] = item + '/index.php'
    return result

def get_php():
    try:
        request = requests.get(config['env']['phpinfo'], params={'format': 'json'})
        return request.json()
    except requests.exceptions.RequestException:
        return {'version': '<span class="text-danger">Cannot fetch, is Apache and Php containers running?</span>'}

def get_containers(all = True):
    result = {}

    try:
        containers_list = client.containers.list(all=all)
    except docker.errors.APIError:
        print("Error accessing the docker API. Is the daemon running?")
        raise

    for container in containers_list:
        service = container.labels.get('com.docker.compose.service')
        if not service:
            service = container.name

        if container.name not in config.get('hide'):
            result.update({service: format_container(container, False)})

    sorted_result = {}
    for key in sorted(result.keys()):
        sorted_result[key] =  result[key]

    return sorted_result

def format_container(container, keyed = True):
    result = {}
    service = container.labels.get('com.docker.compose.service')
    if not service:
        service = container.name
    ports_raw = container.attrs['NetworkSettings']['Ports']
    ports = {}
    for port, host_port in ports_raw.items():
        port = port.replace('/tcp', '')
        ports[port] = 'private'
        if host_port is not None:
            ports[port] = host_port[0]['HostPort']
    status = container.attrs['State']['Status']
    network = list(container.attrs['NetworkSettings']['Networks'].values())
    if network[0] and network[0].get('IPAddress'):
        ip = network[0]['IPAddress']
    else:
        ip = ''
    # Provide a more digest values.
    result = {
        'name': container.name,
        'service': service,
        'id': container.id,
        'short_id': container.short_id,
        'status': status,
        'ports': ports,
        'ip': ip,
        'labels': container.labels,
        # 'raw': container.attrs,
    }
    if keyed:
        result[service] = result
    return result

def get_services():
    return get_containers()

def get_mysql():
    return get_containers()

def get_pgsql():
    return get_containers()

def get_env():
    result = {}
    stack_env = load_dotenv(dotenv_path=config['env']['stack'])
    result['HOST_TOOLS_PORT'] = os.getenv('HOST_TOOLS_PORT');
    result['HOST_DASHBORAD_PORT'] = os.getenv('HOST_DASHBORAD_PORT');
    result['MYSQL_DATABASE'] = os.getenv('MYSQL_DATABASE');
    result['MYSQL_ROOT_PASSWORD'] = os.getenv('MYSQL_ROOT_PASSWORD');
    result['MYSQL_USER'] = os.getenv('MYSQL_USER');
    result['MYSQL_PASSWORD'] = os.getenv('MYSQL_PASSWORD');
    result['MYSQL_ALLOW_EMPTY_PASSWORD'] = os.getenv('MYSQL_ALLOW_EMPTY_PASSWORD');
    result['POSTGRES_DB'] = os.getenv('POSTGRES_DB');
    result['POSTGRES_USER'] = os.getenv('POSTGRES_USER');
    result['POSTGRES_PASSWORD'] = os.getenv('POSTGRES_PASSWORD');
    result['APACHE_HOST_DASHBORAD_PORT'] = os.getenv('APACHE_HOST_DASHBORAD_PORT');
    result['APACHE_HOST_ROOT_PORT'] = os.getenv('APACHE_HOST_ROOT_PORT');
    result['NGINX_HOST_HTTP_PORT'] = os.getenv('NGINX_HOST_HTTP_PORT');
    return result

def get_data():
    result = {}
    result['settings'] = config
    result['vhost'] = get_vhost()
    result['nginx'] = get_nginx()
    result['tools'] = get_tools()
    result['env'] = get_env()
    result['php'] = {}
    result['containers'] = get_containers()
    return result

def render_block(block_name, data):
    if os.path.isfile("templates/card_" + block_name + ".html"):
        tpl = "card_" + block_name + ".html"
        rows = []
        try:
            get = globals()['get_' + block_name]
            data[block_name] = get()
        except KeyError:
            data[block_name] = get_containers()

        if block_name == "containers":
            for key in data['containers']:
                row = render_template("row_container.html", container = data['containers'][key])
                rows.append(row)

        html = render_template(tpl, data = data, rows = rows)
        return html

def is_jsonable(x):
    try:
        json.dumps(x)
        return True
    except:
        return False

def lines_that_contain(string, fp):
    return [line for line in fp if string in line]

@app.route('/')
def index():
    return render_template("index.html", data = data)

@app.route('/blocks', methods=['GET'])
def show_blocks():
    result = {}
    data = get_data()
    data['php'] = get_php()
    blocks = config.get('blocks').get('left') + config.get('blocks').get('right')
    for block_name in blocks:
        result[block_name] = {'name': block_name, 'html': render_block(block_name, data)}
    return jsonify(result)

@app.route('/block/<block_name>', methods=['GET'])
def show_block(block_name):
    data = get_data()
    data['php'] = get_php()
    html = render_block(block_name, data)
    return jsonify({'name': block_name, 'html': html})

@app.route('/block/<block_name>/<container_id>', methods=['GET'])
def show_block_row(block_name, container_id):
    try:
        container = client.containers.get(container_id)
        html = render_template("row_container.html", container = format_container(container, False))
    except:
        html = ""
    return jsonify({'name': block_name, 'html': html})

@app.route('/api/container/<container_id>', methods=['GET'])
def get_container(container_id):
    container = client.containers.get(container_id)
    return jsonify(format_container(container, False))

@app.route('/api/container/<container_id>/<action>', methods=['GET'])
def block_action(container_id, action):
    container = client.containers.get(container_id)
    result = {}
    message = ''
    if action == "logs":
        message = 'Logs for'
        result['stdout (tail 20)'] = container.logs(stderr=False, tail=20).decode("utf-8").split("\n")
        result['stderr (tail 20)'] = container.logs(stdout=False, tail=20).decode("utf-8").split("\n")
    elif action == "top":
        message = 'Top for'
        top = container.top(ps_args="aux")
        # Header
        result['top'] = [' | '.join(top['Titles'])]
        for line in top['Processes']:
            result['top'].append(' | '.join(line))
    elif action == "restart":
        message = 'Restarting'
        container.restart()
        container.reload()
        result['result'] = ['Restarted ' + container.name + ', status is ' + container.status]
    elif action == "start":
        message = 'Start'
        container.start()
        container.reload()
        result['result'] = [container.status.capitalize()]
    elif action == "stop":
        message = 'Stop'
        container.stop()
        container.reload()
        result['result'] = [container.status.capitalize()]
    elif action == "status":
        message = 'Status'
        container.reload()
        result['result'] = [container.status.capitalize()]
    elif action == "remove":
        message = 'Remove'
        container.remove()
        result['result'] = [container.status.capitalize()]

    return jsonify({
        'id': container_id,
        'name': container.name,
        'action': action,
        'result': result,
        'message': message + ' ' + container.name,
    })

# Init our data with minimum.
data['env'] = get_env()
data['settings'] = config;

if __name__ == '__main__':
    app.run(debug=False, host='0.0.0.0', threaded=True)
