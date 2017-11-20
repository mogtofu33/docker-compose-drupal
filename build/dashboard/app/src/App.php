<?php

namespace Dashboard;

use Docker\Docker;
use Docker\API\Model\ExecConfig;
use Docker\API\Model\ExecStartConfig;
use Docker\Manager\ExecManager;

// use Symfony\Component\Debug\Debug;
// Debug::enable();

/**
 * Class App.
 *
 * A minimal Docker Dashboard used for Docker Compose Drupal project.
 */
Class App {

  /**
   * The docker service.
   *
   * @var \Docker\Docker
   */
  protected $docker;

  /**
   * Retain information on host, web host and services.
   *
   * @var Array
   */
  public $vars;

  /**
   * The services to hide.
   *
   * @var Array
   */
  public static $services_to_hide = ['dashboard'];

  /**
   * The db services.
   *
   * @var Array
   */
  public static $db_services = [
    'pgsql' => 'POSTGRES',
    'mysql' => 'MYSQL',
  ];

  /**
   * Containers list.
   *
   * @var Array
   */
  public $containers;

  /**
   * Constructs a new App object.
   */
  public function __construct() {
    $this->docker = new Docker();
    $this->containers = $this->getContainers();
    $this->initFolders();
    $this->init();
  }

  /**
   * Instanciate values needed to be shown.
   */
  protected function init() {
    $this->vars['dashboard'] = $this->vars['apache'] = [];
    $host = $_SERVER['SERVER_NAME'];
    if ($host == '0.0.0.0') {
      $host = 'localhost';
    }
    $this->vars['dashboard']['full'] = $_SERVER['HTTP_HOST'];
    $this->vars['dashboard']['host'] = $host;
    $this->vars['dashboard']['tools'] = $_SERVER['HTTP_HOST'] . '/tools/';

    $host_root = getenv('HOST_WEB_ROOT');

    if (null !== getenv('APACHE_HOST_HTTP_PORT')) {
      $port = getenv('APACHE_HOST_HTTP_PORT') == "80" ? "" : ":" . getenv('APACHE_HOST_HTTP_PORT');
    }
    else {
      $port = '';
    }

    $this->vars['apache']['full'] = $host . $port;

    $this->vars['dashboard']['root'] = $this->parseVhost($host);

    $first_id = reset($this->containers)['id'];
    $this->vars['db_services_env'] = $this->dbInfoFromEnv($first_id);
  }

  /**
   * Get db information from .env file from a container.
   *
   * @param int $id
   *   A container id.
   *
   * @return array
   *   Database informations.
   */
  private function dbInfoFromEnv($id) {
    $container = $this->docker->getContainerManager()->find($id);
    $env_array = $container->getConfig()->getEnv();
    $env = [];
    foreach ($env_array as $env_value) {
      $val = explode('=', $env_value);
      $env[$val[0]] = $val[1];
    }

    $db_services_env = [];

    foreach ($env as $k => $e) {
      foreach ($this::$db_services as $service => $value) {
        if (strpos($k, $value) !== FALSE) {
          $name = str_ireplace($service, '', $k);
          $name = trim(str_replace('_', ' ', $name));
          if (strpos($name, 'DB') !== FALSE || strpos($name, 'DATABASE') !== FALSE) {
            $db_services_env[$service]['Database'] = $e;
          }
          else if (strpos($name, 'USER') !== FALSE) {
            $db_services_env[$service]['Username'] = $e;
          }
          else {
            $label = ucfirst(strtolower(str_replace('_', ' ', $name)));
            $db_services_env[$service][$label] = $e;
          }
        }
      }
    }

    return $db_services_env;
  }

  /**
   * Populate a list of folders.
   *
   * @param string $path
   *   A path to look for.
   * @param string $project_path
   *   A path to look for.
   */
  protected function initFolders($path = '/var/www/dashboard/', $project_path = '/var/www/localhost') {
    // Get tools from folder.
    $tools = @array_diff(scandir($path . 'tools'), array('..', '.', '.htaccess'));
    $formatted_tools = [];
    foreach ($tools as $k => $tool) {
      $formatted_tools[$k]['name'] = str_replace('.php', '', str_replace('/index.php', '', ucfirst($tool)));
      if (substr($tool, -4) !== '.php') {
        $formatted_tools[$k]['href'] = '/tools/' . $tool . '/index.php';
      }
      else {
        $formatted_tools[$k]['href'] = '/tools/' .$tool;
      }
    }
    $this->vars['tools'] = $formatted_tools;
    // Get current folders exept drupal and tools.
    $this->vars['folders'] = @array_diff(scandir($project_path), array('..', '.', '.htaccess', 'cgi-bin'));
  }

  /**
   * Process some actions on a container.
   *
   * @param string $action
   *   The action name.
   * @param string $id
   *   The container id or an url.
   * @param array $request
   *   The full HTTP request.
   *
   * @return string
   *   A json response keyed with message, result, id, action and level.
   */
 public function processAction($action = 'state', $id = NULL, $request = []) {
    // Default message returned.
    $response = [
      'action' => $action,
      'id' => $id,
      'message' => NULL,
      'level' => 'info',
      'result' => [],
    ];

    if (isset($action) && isset($id)) {
      // Get container info.
      $container = $this->docker->getContainerManager()->find($id);
      $name = str_replace('/', '', $container->getName());

      // Process actions.
      switch ($action) {
        case 'restart':
          $restart = $this->docker->getContainerManager()->restart($id, ['t' => 5]);
          $response['message'] = 'Container ' . $name. ' restarted!';
          $response['level'] = 'success';
          break;
        case 'logs':
          if (isset($request['tail'])) {
            $tail = (int)$request['tail'];
          }
          else {
            $tail = 30;
          }
          $logs = $this->docker->getContainerManager()->logs($id, ['tail' => $tail, 'stderr' => TRUE, 'stdout' => TRUE]);
          if (count($logs['stderr']) || count($logs['stdout'])) {
            $response['result']['stderr'] = implode('', $logs['stderr']);
            $response['result']['stdout'] = implode('', $logs['stdout']);
            $response['message'] = 'Last ' . $tail . ' logs on container ' . $name;
          }
          else {
            $response['message'] = 'No logs on container ' . $name;
          }
          break;
        case 'top':
          $top = $this->docker->getContainerManager()->listProcesses($id, ['ps_args' => 'aux']);
          $response['result']['top'][] = implode(' | ', $top->getTitles());
          foreach ($top->getProcesses() as $process) {
            $response['result']['top'][] = implode(' | ', $process);
            $response['message'] = 'Top on container ' . $name;
          }
          $response['result']['top'] = implode("\r", $response['result']['top']);
          break;
        case 'state':
          if ($container->getstate()->getRunning()) {
            $response['message'] = 'Container ' . $name . ' is running';
            $response['level'] = 'success';
          }
          else {
            $response['message'] = 'Container ' . $name . ' is stoped';
            $response['level'] = 'warning';
          }
          break;
        case 'exec':
          $exec = $this->exec($id, explode(' ', $request['cmd']));
          $response['level'] = 'success';
          if (strpos($exec['stdout'], 'rpc error') !== FALSE) {
            $response['level'] = 'error';
          }
          $response['result']['stdout'] = $exec['stdout'];
          if (!empty($exec['stderr'])) {
            $response['level'] = 'error';
            $response['result']['stderr'] = $exec['stderr'];
          }
          break;
        default:
          $response['level'] = 'error';
          $response['message'] = 'Invalid action.';
      }
    }
    else {
      $response['level'] = 'error';
      $response['message'] = 'Invalid request.';
    }
    return json_encode($response);
  }

  /**
   * Get formatted list of containers.
   *
   * @return array
   *   Containers with information formatted in an array.
   */
  public function getContainers() {
    $containers_list = [];

    // Get our main source of information.
    $containers = $this->docker->getContainerManager()->findAll();

    // Pre-format our values.
    foreach ($containers AS $c) {
      $id = $c->getId();
      $name = $c->getNames()[0];
      $labels = $c->getLabels()->getArrayCopy();
      $service = isset($labels['com.docker.compose.service']) ? $labels['com.docker.compose.service'] : '';
      $state = $c->getState();
      $status = $c->getStatus();
      $ports = $c->getPorts();
      $network = $c->getNetworkSettings()->getNetworks()->getArrayCopy();
      $ip = $network[key($network)]->getIPAddress();
      $containers_list[$service] = [
        'id' => $id,
        'service' => ucfirst($service),
        'name' => str_replace('/', '', $name),
        'state' => ucfirst($state),
        'state_raw' => $state,
        'status' => $status,
        'ports' => [],
        'ip' => $ip,
      ];
      $has_public_access = FALSE;
      foreach ($ports AS $p) {
        $private = $p->getPrivatePort();
        $public = $p->getPublicPort();
        if ($public) {
          $has_public_access = TRUE;
        }
        $containers_list[$service]['ports'][$private] = [
          'private' => $private ? $private : NULL,
          'public' => $public ? $public : NULL,
          'type' => $p->getType(),
          'mode' => 'http',
        ];
        // Filter port to match https and exclude non http.
        $https_port = ['443', '8443'];
        if (in_array($public, $https_port)) {
          $containers_list[$service]['ports'][$private]['mode'] = 'https';
        }
        $non_http = ['389', '3306', '11211', '5432', '6379'];
        if (in_array($public, $non_http)) {
          $containers_list[$service]['ports'][$private]['mode'] = NULL;
        }
      }
      ksort($containers_list[$service]['ports']);
      $containers_list[$service]['is_public'] = $has_public_access;
    }
    ksort($containers_list);
    return $containers_list;
  }

  /**
   * Get php info from cmd on the apache container.
   *
   * @return array
   *   Php result information formatted.
   */
  public function getPhpInfo() {
    $info = ini_get_all(NULL, FALSE);
    $result = [
      'PhpFpm' => '<span class="badge badge-info get-data" data-url="fpm-ping">Checking...</span>',
      'Memory limit' => $info['memory_limit'],
      'Max execution time' => $info['max_execution_time'],
      'Upload max filesize' => $info['upload_max_filesize'],
      'Max input vars' =>  $info['max_input_vars'],
      'Display errors' => ($info['display_errors'] === "1") ? 'On' : 'Off',
      'Date timezone' => $info['date.timezone'],
      'Sendmail' => $info['sendmail_path'],
      'Opcache' => ($info['opcache.enable'] === "1") ? '<span class="badge badge-success">Enabled</span>' : '<span class="badge badge-warning">Disabled</span>',
      'Xdebug' => '<span class="badge badge-warning">Disabled</span>',
    ];
    if (isset($info['xdebug.default_enable'])) {
      $result['Xdebug'] = ($info['xdebug.default_enable'] === "1") ? '<span class="badge badge-success">Enabled</span>' : '<span class="badge badge-warning">Disabled</span>';
      if (isset($info['xdebug.max_nesting_level'])) {
        $result['Xdebug max nesting level'] = $info['xdebug.max_nesting_level'];
      }
    }
    return $result;
  }

  /**
   * Get php info from cmd on the apache container.
   *
   * @return string
   *   Php version.
   */
  public function getPhpVersion() {
    // $cmd = $this->exec('ddd-apache', ["php", "-r", "print phpversion();"]);
    // return $cmd['stdout'];
    return phpversion();
  }

  /**
   * Execs a command in a running container, and returns the result. Note that
   * docker doesn't support returning the exit code.
   *
   * @param string $container
   *   Container identifier
   * @param array $cmd
   *   Array of commands to send to the container
   * @param bool $resultArray
   *  GFlag to return result as array.
   *
   * @return array
   *   Keyed stdout and stderr result.
   */
  private function exec($container, $cmd, $tty = TRUE) {

    if (!is_array($cmd)) {
      throw new \Exception("cmd must be an array of strings");
    }

    $ec = new ExecConfig;
    $ec->setTty($tty);
    $ec->setAttachStdout(true);
    $ec->setAttachStderr(true);
    $ec->setCmd($cmd);

    $sc = new ExecStartConfig;
    $sc->setDetach(false);

    $execid = $this->docker->getExecManager()->create($container, $ec)->getId();
    $stream = $this->docker->getExecManager()->start($execid, $sc, [], ExecManager::FETCH_STREAM);

    $stdoutResult = $stderrResult = '';

    $stream->onStdout(function ($stdout) use (&$stdoutResult) {
      $stdoutResult .= $stdout;
    });
    $stream->onStderr(function ($stderr) use (&$stderrResult) {
      $stderrResult .= $stderr;
    });
    $stream->wait();

    return ['stdout' => $stdoutResult, 'stderr' => $stderrResult];
  }

  /**
   * Helper to parse apavche vhost file.
   *
   * @param string $host
   *   Container identifier
   *
   * @return array
   *   Keyed stdout and stderr result.
   */
  private function parseVhost($host) {
    $hosts = [];
    $vhost = trim(file_get_contents('/etc/apache2/vhost/vhost.conf'));
    $vhost_lines = explode("\n", $vhost);
    $apache_root = [];
    foreach ($vhost_lines as $vhost_line) {
      $vhost_line = trim($vhost_line);
      if (substr($vhost_line, 0, 1) == '#' || empty($vhost_line)) {
        continue;
      }
      preg_match('#<VirtualHost (.*?)>#', $vhost_line, $match_port);
      if (isset($match_port[1])) {
        $vhost_port = [
          'host' => $host,
          'port' => str_replace('*:', '', $match_port[1]),
        ];
      }
      preg_match("/^(?P<key>\w+)\s+(?P<value>.*)/", $vhost_line, $matches);

      if (isset($matches['key'])) {
        if ($matches['key'] == 'ServerName') {
          $vhost_port['name'] = $matches['value'];
        }
        if ($matches['key'] == 'ServerAlias') {
          $vhost_port['alias'] = $matches['value'];
        }
        if ($matches['key'] == 'DocumentRoot' && $matches['value']  != getenv('DOCUMENT_ROOT')) {
          $apache_root[] = $vhost_port + ['root' => str_replace('"', '', $matches['value'])];
        }
      }
    }
    if (count($apache_root)) {
      return $apache_root;
    }
    else {
      return [[
        "host" => "localhost",
        "name" => "",
        "alias" => "",
        "port" => "80",
        "root" => "/var/www/localhost/drupal/web",
      ]];
    }
  }
}
