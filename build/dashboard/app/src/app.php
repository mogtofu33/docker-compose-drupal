<?php

/*
 * Docker minimal dashboard.
 */

ini_set('display_errors', 0);

require_once __DIR__.'/../vendor/autoload.php';

// use Symfony\Component\Debug\Debug;
// Debug::enable();

use Docker\Docker;
$docker = new Docker();

// POST or GET actions.
$result = $message = NULL;
if (isset($_REQUEST['action'])) {
  if (isset($_REQUEST['id'])) {
    switch ($_REQUEST['action']) {
      case 'restart':
        $container = $docker->getContainerManager()->find($_REQUEST['id']);
        $restart = $docker->getContainerManager()->restart($_REQUEST['id'], ['t' => 5]);
        $message = [
          'type' => 'success',
          'text' => 'Container ' . STR_REPLACE('/', '', $container->getName()) . ' restarted!',
        ];
        break;
      case 'log':
        $logs = $docker->getContainerManager()->logs($_REQUEST['id'], ['tail' => 30, 'stderr' => TRUE, 'stdout' => TRUE]);
        if (count($logs['stderr'])) {
          $result = $logs['stderr'];
        }
        else {
          $result = ['No logs.'];
        }
        break;
      case 'top':
        $top = $docker->getContainerManager()->listProcesses($_REQUEST['id'], ['ps_args' => 'aux']);
        $result[] = $top->getTitles();
        foreach ($top->getProcesses() as $process) {
          $result[] = $process;
        }
        break;
    }
  }
  if ($result) {
    echo json_encode($result);
    exit;
  }
}

// Variables
$apache = $docker->getContainerManager()->find('ddd-apache');

$dashboard_web = $_SERVER['REMOTE_ADDR'];
$dashboard_port = $_SERVER['SERVER_PORT'];
$dashboard_host = $dashboard_web . ':' . $dashboard_port;

$host_root = getenv('HOST_WEB_ROOT');
$container_root = getenv('DOCUMENT_ROOT');
$host = $_SERVER['SERVER_NAME'];

if ($host == '0.0.0.0') {
  $host = 'localhost';
}
$port = $_ENV['APACHE_HOST_HTTP_PORT'];
$web_host = $host . ':' . $port;

$services_to_hide = ['Apache', 'Dashboard'];

// dump($_ENV);
// dump($_SERVER);

// Get tools from folder.
$tools = array_diff(scandir('/var/www/html/TOOLS'), array('..', '.', '.htaccess'));
$tools_extra = array_diff(scandir('/var/www/html/third_party_tools'), array('..', '.', '.htaccess'));
// Get current folders exept drupal and tools.
$folders = array_diff(scandir('/www'), array('..', '.', '.htaccess', 'TOOLS'));

// Get our main source of information.
$containers = $docker->getContainerManager()->findAll();
$containers_list = [];
// Pre-format our values.
foreach ($containers AS $c) {
  $containers_list[$c->getId()] = [
    'id' => $c->getId(),
    'service' => ucfirst($c->getLabels()->getArrayCopy()['com.docker.compose.service']),
    'service_raw' => $c->getLabels()->getArrayCopy()['com.docker.compose.service'],
    'name' => str_replace('/', '', $c->getNames()[0]),
    'state' => ucfirst($c->getstate()),
    'status' => $c->getstatus(),
    'ports' => [],
  ];
  $has_public_access = FALSE;
  foreach ($c->getPorts() AS $p) {
    if ($p->getPublicPort()) {
      $has_public_access = TRUE;
    }
    $containers_list[$c->getId()]['ports'][] = [
      $p->getPrivatePort(),
      $p->getPublicPort(),
    ];
  }
  $containers_list[$c->getId()]['is_public'] = $has_public_access;
}
