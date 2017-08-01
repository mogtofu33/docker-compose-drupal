<?php

/*
 * Docker minimal dashboard.
 */
namespace Dashboard;

use Docker\Docker;
use Docker\API\Model\ExecConfig;
use Docker\API\Model\ExecStartConfig;
use Docker\Manager\ExecManager;

// use Symfony\Component\Debug\Debug;
// Debug::enable();

Class App {

  protected $docker;
  // protected $apache_container;

  public $host;
  public $web_host;

  public static $services_to_hide = ['apache', 'dashboard'];
  public static $db_services = [
    'pgsql' => 'POSTGRES',
    'mysql' => 'MYSQL',
  ];
  public $db_services_env;

  public $container_root;

  public $tools = [];
  public $extra_tools = [];
  public $folders = [];
  // public $running_services;
  public $containers;

  function __construct() {
    $this->docker = new Docker();
    $this->containers = $this->getContainers();

    // $this->apache_container = $this->docker->getContainerManager()->find('ddd-apache');
    $this->init();
    $this->initFolders();
  }

  protected function init() {
    // dump($this->apache_container);
    $host = $_SERVER['SERVER_NAME'];
    if ($host == '0.0.0.0') {
      $host = 'localhost';
    }
    $this->host['full'] = $_SERVER['HTTP_HOST'];
    $this->host['host'] = $host;
    $this->host['tools'] = $_SERVER['HTTP_HOST'] . '/TOOLS/';
    // $this->host['port'] = $_SERVER['SERVER_PORT'];


    $host_root = getenv('HOST_WEB_ROOT');
    // $host = $_SERVER['SERVER_NAME'];
    // if ($host == '0.0.0.0') {
    //   $host = 'localhost';
    // }
    // dump($this->apache_container->getNetworkSettings()->getNetworks());
    $port = $_ENV['APACHE_HOST_HTTP_PORT'] == "80" ? "" : ":" . $_ENV['APACHE_HOST_HTTP_PORT'];
    // $this->web_host = $host . $port;
    $this->web_host['full'] = $host . $port;
    $this->web_host['host'] = $host;
    $this->web_host['port'] = $port;

    $this->container_root = getenv('DOCUMENT_ROOT');
    foreach ($_ENV as $k => $env) {
      foreach ($this::$db_services as $service => $value) {
        if (strpos($k, $value) !== FALSE) {
          $this->db_services_env[$service][$k] = $env;
          $string = explode('_', $k);
          $name = end($string);
          if (strpos($name, 'USER') !== FALSE) {
            $this->db_services_env[$service]['username'] = $env;
          }
          if (strpos($name, 'DB') !== FALSE || strpos($name, 'DATABASE') !== FALSE) {
            $this->db_services_env[$service]['db'] = $env;
          }
        }
      }

    }
  }

  protected function initFolders($path = '/var/www/html/', $project_path = '/www') {
    // Get tools from folder.
    $this->tools = array_diff(scandir($path . 'TOOLS'), array('..', '.', '.htaccess'));
    $this->extra_tools = @array_diff(scandir($path . 'third_party_tools'), array('..', '.', '.htaccess'));
    // Get current folders exept drupal and tools.
    $this->folders = array_diff(scandir($project_path), array('..', '.', '.htaccess', 'TOOLS'));
  }

  public function processAction($action, $id = NULL) {
    // POST or GET actions.
    $response = [
      'action' => $action,
      'id' => $id,
      'message' => NULL,
      'level' => 'info',
      'result' => NULL,
    ];

    if (isset($action) && isset($id)) {
      $container = $this->docker->getContainerManager()->find($id);
      $name = str_replace('/', '', $container->getName());
      switch ($action) {
        case 'restart':
          $restart = $this->docker->getContainerManager()->restart($id, ['t' => 5]);
          $response['message'] = 'Container ' . $name. ' restarted!';
          $response['level'] = 'success';
          break;
        case 'logs':
          $logs = $this->docker->getContainerManager()->logs($id, ['tail' => 30, 'stderr' => TRUE, 'stdout' => TRUE]);
          if (count($logs['stderr'])) {
            $response['result'] = implode('', $logs['stderr']);
            $response['message'] = 'Logs on container ' . $name;
          }
          else {
            $response['message'] = 'No logs on container ' . $name;
          }
          break;
        case 'top':
          $top = $this->docker->getContainerManager()->listProcesses($id, ['ps_args' => 'aux']);
          $response['result'][] = implode(' | ', $top->getTitles());
          foreach ($top->getProcesses() as $process) {
            $response['result'][] = implode(' | ', $process);
            $response['message'] = 'Top on container ' . $name;
          }
          $response['result'] = implode("\r", $response['result']);
          break;
        case 'state':
          // $response['message'] = $container->getstate();
          // dump($container);
          break;
        case 'status':
          // $response['message'] = $container->getstatus();
          break;
        default:
          $response['level'] = 'error';
          $response['message'] = 'Invalid action.';
      }
      return json_encode($response);
    }
  }

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
        if ($p->getPublicPort()) {
          $has_public_access = TRUE;
        }
        $containers_list[$service]['ports'][] = [
          'private' => $p->getPrivatePort(),
          'public' => $p->getPublicPort(),
        ];
      }
      $containers_list[$service]['is_public'] = $has_public_access;
    }
    return $containers_list;
  }

  public function getPhpInfo() {
    // $cmd = $this->exec('ddd-apache', ["touch", "/www/drupal/web/phpinfo.php"]);
    /* $cmd = $this->exec('ddd-apache', ["bash", "-c", "echo '<?php phpinfo(); ?>' >> /www/drupal/web/phpinfo.php"]);*/
    // $cmd = $this->exec('ddd-apache', ["chown", "apache:www-data", "/www/phpinfo.php"]);
    // $cmd = $this->exec('ddd-apache', ["rm", "f", "/www/drupal/web/phpinfo.php"]);

    $cmd = $this->exec('ddd-apache', ["php", "-r", "print json_encode(ini_get_all());"]);
    $info = json_decode($cmd['stdout']);
    $result = [
      'Memory limit' => $info->memory_limit->local_value,
      // 'Max execution time' => $info->max_execution_time->local_value,
      'Upload max filesize' => $info->upload_max_filesize->local_value,
      'Max input vars' =>  $info->max_input_vars->local_value,
      'Display errors' => ($info->display_errors->local_value === "1") ? 'On' : 'Off',
      'Date timezone' => $info->{"date.timezone"}->local_value,
      'Sendmail' => $info->sendmail_path->local_value,
      'Opcache' => ($info->{"opcache.enable"}->local_value === "1") ? '<span class="label label-success">Enabled</span>' : '<span class="label label-warning">Disabled</span>',
      'Xdebug' => ($info->{"xdebug.default_enable"}->local_value === "1") ? '<span class="label label-warning">Enabled</span>' : '<span class="label label-success">Disabled</span>',
      'Xdebug max nesting level' => $info->{"xdebug.max_nesting_level"}->local_value,
    ];
    return $result;

  }

  public function getPhpVersion() {
    $cmd = $this->exec('ddd-apache', ["php", "-r", "print phpversion();"]);
    return $cmd['stdout'];
  }

  /**
   * Execs a command in a running container, and returns the result. Note that
   * docker doesn't support returning the exit code.
   *
   * @param string $container     Container identifier
   * @param array $cmd            Array of commands to send to the container
   *
   * @returns array [ stdout, stderr ]
   */

  public function exec($container, $cmd, $resultArray = FALSE) {

    if (!is_array($cmd)) {
      throw new \Exception("cmd must be an array of strings");
    }

    $ec = new ExecConfig;
    $ec->setTty(true);
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

    if ($resultArray) {
      return ['stdout' => explode("\r\n", $stdoutResult), 'stderr' => explode("\r\n", $stderrResult)];
    }
    else {
      return ['stdout' => $stdoutResult, 'stderr' => $stderrResult];
    }
  }
}
