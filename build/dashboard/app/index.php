<?php
require_once __DIR__.'/vendor/autoload.php';

use Dashboard\App;
$app = new App();

// Handle POST/GET requests.
if (isset($_REQUEST['action']) && isset($_REQUEST['id'])) {
  echo $app->processAction($_REQUEST['action'], $_REQUEST['id'], $_REQUEST);
  exit;
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <!-- Required meta tags -->
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">

    <title>Docker Compose Drupal - Dev stack</title>

    <link rel="stylesheet" href="css/styles.css">

</head>
<body>
  <!-- Page Content -->
  <div class="container-fluid my-3">

    <div class="row">
      <div class="col">
        <h4>
          <a href="https://github.com/Mogtofu33/docker-compose-drupal" target="_blank"><span class="badge badge-info">Docker Compose Drupal</span></a>
          <small>Docker full stack for simple Drupal dev.</small>
        </h4>
        <p>
          <a class="btn btn-sm btn-outline-info" href="https://github.com/Mogtofu33/docker-compose-drupal" target="_blank" role="button">
            <span class="octicon octicon-home" aria-hidden="true"></span> Project homepage
          </a>
          <a class="btn btn-sm btn-outline-secondary" href="https://github.com/Mogtofu33/docker-compose-drupal/blob/master/README.md" target="_blank">
            <span class="octicon octicon-book" aria-hidden="true"></span> Documentation
          </a>
          <a class="btn btn-sm btn-outline-warning" href="https://github.com/Mogtofu33/docker-compose-drupal/issues" target="_blank">
            <span class="octicon octicon-bug" aria-hidden="true"></span> Bug report
          </a>
        </p>
      </div>
    </div>

    <div class="alert alert-success alert-dismissible fade in" role="alert" id="message" style="display:none;">
      <button class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">×</span></button>
      <div class="message"></div>
    </div>

    <div class="row">
      <div class="col">
        <section class="card mb-3">
          <div class="card-header">Your sites <small>(You can edit config/apache/vhost.conf)</small></div>
          <table class="table table-hover table-sm table-responsive-md mb-0">
            <thead>
              <tr>
                <th>Host</th>
                <!-- <th>Alias</th> -->
                <th>Document Root</th>
            </thead>
            <tbody>
              <?php foreach ($app->vars['dashboard']['root'] as $host): ?>
                <tr>
                  <td>
                    <a target="_blank" href="<?php print $host['link']; ?>">
                      <?php print $host['host'] . ':' . $host['port']; ?>
                      <span class="octicon octicon-link-external" aria-hidden="true"></span>
                    </a>
                  </td>
<!--                   <td>
                     <a target="_blank" href="<?php ($host['port'] == '443') ? print 'https:' : ''; ?>//<?php print $host['alias']; ?>">
                      <?php print $host['alias']; ?>
                      <span class="octicon octicon-link-external" aria-hidden="true"></span>
                    </a>
                  </td> -->
                  <td>
                    <code><?php print $host['root']; ?></code>
                  </td>
                </tr>
              <?php endforeach; ?>
            </tbody>
          </table>

        </section>

        <section class="card mb-3">
          <div class="card-header">Containers running</div>
          <table class="table table-hover table-sm table-responsive-md mb-0">
            <thead>
              <tr>
                <th></th>
                <th>Port(s)<br><small>(Internal | Public)</small></th>
                <th>Container name</th>
                <th>Container IP</th>
                <th>Status</th>
                <th>Details</th>
                <!-- <th>Actions</th> -->
            </thead>
            <tbody>
            <?php foreach ($app->containers AS $container): ?>
              <tr class="<?php print $container['id']; ?>">
                <th><?php print $container['service']; ?></th>
                <td>
                  <ul class="list-unstyled mb-0">
                  <?php foreach ($container['ports'] AS $port): ?>
                    <li><?php print $port['private']; if (isset($port['public'])): print ' > ' . $port['public'];  endif; ?></li>
                  <?php endforeach; ?>
                </ul>
                </td>
                <td><code class="copy"><?php print $container['name']; ?></code></td>
                <td><code class="copy"><?php print $container['ip']; ?></code></td>
                <td>
                  <?php print $container['state']; ?>
                </td>
                <td>
                  <button class="btn btn-outline-dark btn-sm" data-toggle="modal" data-target="#myModal" data-action="logs" data-container="<?php print $container['id']; ?>">Logs</button>
                  <button class="btn btn-outline-dark btn-sm" data-toggle="modal" data-target="#myModal" data-action="top" data-container="<?php print $container['id']; ?>">Top</button>
                </td>
                <!-- <td>
                 <button class="btn btn-primary btn-sm action" autocomplete="off" data-container="<?php print $container['id'] ?>" data-action="restart">
                  <span class="octicon" aria-hidden="true"></span> Restart
                 </button>
                </td> -->
              </tr>
            <?php endforeach; ?>
          </table>

          <div class="card-footer">
            <div class="form-inline">
            <label for="exec">Quick command on</label>
            <select class="form-control form-control-sm ml-1" name="id" id="exec">
              <option value="_none">- Select -</option>
              <?php foreach ($app->containers as $c): ?>
              <option value="<?php print $c['id']; ?>"><?php print $c['service']; ?></option>
              <?php endforeach; ?>
            </select>
            </div>
            <div id="terminal" style="display:none;">
              <small>Command are send through <code>docker exec -t</code> as <strong>ROOT</strong>, you can only run direct and simple commands from the system root.<br>For more complex commands you can type in a local terminal: <code class="copy">docker exec -it CONTAINER_NAME /bin/sh</code></small>
              <div class="body"></div>
            </div>
          </div>
        </section>

        <section class="card mb-3">
          <div class="card-header">Services</div>
          <table class="table table-hover table-sm table-responsive-md mb-0">
            <thead>
              <tr>
                <th></th>
                <th>Host access</th>
                <th>Container access</th>
            </thead>
            <tbody>
            <?php foreach ($app->containers AS $service => $container): ?>
              <?php if (!in_array($service, $app::$services_to_hide)): ?>
                <tr class="<?php print $container['id']; ?>">
                  <th><?php print $container['service']; ?></th>
                  <td>
                    <?php if ($container['is_public']): ?>
                      <ul class="list-unstyled mb-0">
                      <?php foreach ($container['ports'] AS $port): ?>
                        <?php if (isset($port['public']) && $port['mode']): ?>
                          <li><a target="_blank" href="<?php print $port['mode']; ?>://<?php print $app->vars['dashboard']['host'] . ':' . $port['public']; ?>"><?php print $port['mode']; ?>://<?php print $app->vars['dashboard']['host'] . ':' . $port['public']; ?> <span class="octicon octicon-link-external" aria-hidden="true"></span></a></li>
                        <?php endif; ?>
                      <?php endforeach; ?>
                      </ul>
                    <?php endif; ?>
                  </td>
                  <td>
                    <ul class="list-unstyled mb-0">
                    <?php foreach ($container['ports'] AS $port): ?>
                      <li><?php print $service . ':' . $port['private']; ?></li>
                    <?php endforeach; ?>
                    </ul>
                  </td>
                </tr>
              <?php endif; ?>
            <?php endforeach; ?>
            </tbody>
          </table>
        </section>

      </div>

      <div class="col">

        <section class="card mb-3">
          <div class="card-header">Development tools</div>
          <table class="table table-hover table-sm table-responsive-md mb-0">
            <?php foreach ($app->vars['tools'] AS $tool): ?>
              <tr>
                <th><?php print $tool['name']; ?></th>
                <td class="text-center">
                  <?php if ($tool['name'] == 'Adminer' || $tool['name'] == 'AdminerExtended'): ?>
                  <a target="_blank" href="<?php print $tool['href']; ?>" class="btn btn-info btn-sm" role="button">Access <span class="octicon octicon-link-external" aria-hidden="true"></span></a>
                  <?php else: ?>
                    <button class="btn btn-sm btn-info" data-toggle="modal" data-target="#myModal" data-action="get" data-url="<?php print $tool['href']; ?>" data-title="<?php print $tool['name']; ?>">Access</button>
                    <small><a target="_blank" title="Open in a new window" href="<?php print $tool['href']; ?>" class="badge badge-light" role="button"><span class="octicon octicon-link-external" aria-hidden="true"></span></a></small>
                  <?php endif; ?>
                  </td>
              </tr>
            <?php endforeach; ?>
          </table>
        </section>

        <?php foreach ($app->containers AS $service => $container): ?>
        <?php if (in_array($service, array_keys($app::$db_services))): ?>
        <section class="card mb-3">
          <div class="card-header"><strong><?php print ucfirst($service); ?></strong> connection information</div>
          <table class="table table-hover table-sm table-responsive-md mb-0">
            <tr>
              <th>Hostname</th>
              <td><code><?php print $service; ?></code></td>
            </tr>
            <tr>
              <th>Docker Ip</th>
              <td><code><?php print $container['ip']; ?></code></td>
            </tr>
            <tr>
              <th>Port</th>
              <td><code class="copy"><?php print end($container['ports'])['private']; ?></code></td>
            <?php if (isset($app->vars['db_services_env'][$service])): ?>
            <?php foreach ($app->vars['db_services_env'][$service] AS $env => $value): ?>
            </tr>
                <tr>
                  <th><?php print $env; ?></th>
                  <td><code class="copy"><?php print $value; ?></code></td>
                </tr>
            <?php endforeach; ?>
            <?php endif; ?>
          </table>
          <div class="card-footer">
            <?php if (isset($app->vars['db_services_env'][$service])): ?>
            <a target="_blank" href="http://<?php print $app->vars['dashboard']['tools'] . 'adminer.php'; ?>?<?php print $service; ?>=<?php print $service; ?>&amp;server=<?php print $service; ?>&amp;username=<?php print $app->vars['db_services_env'][$service]['Username']; ?>&db=<?php print $app->vars['db_services_env'][$service]['Database']; ?>" class="btn btn-info btn-sm" role="button">Manage <span class="octicon octicon-link-external" aria-hidden="true"></span></a>
            <?php endif; ?>
          </div>
        </section>
        <?php endif; ?>
        <?php endforeach; ?>
        <section class="card mb-3">
          <div class="card-header">PHP information</div>
          <table class="table table-hover table-sm table-responsive-md mb-0">
            <tr>
              <th>PHP Version</th>
              <td><code><?php print $app->getPhpVersion(); ?></code></td>
            </tr>
            <tr>
              <th>PHP ini</th>
              <td>
                <code>config/php/php.ini</code>
                <small>Need to restart apache if edited.</small>
              </td>
            </tr>
            <?php $php_info = $app->getPhpInfo(); ?>
            <?php foreach ($php_info AS $label => $value): ?>
              <tr>
                <th><?php print $label; ?></th>
                <td>
                <?php if ($label == 'Opcache' || $label == 'Xdebug' || $label == 'PhpFpm'): ?>
                  <?php print $value; ?>
                <?php else: ?>
                <code><?php print $value; ?></code>
              <?php endif; ?>
              </td>
              </tr>
            <?php endforeach; ?>
          </table>
          <div class="card-footer">
            <small>View more details in the server's <a target="_blank" href="/tools/phpinfo.php">phpinfo() <span class="octicon octicon-link-external" aria-hidden="true"></span></a> report</small>
          </div>
        </section>

      </div>
    </div>
    <hr>
    <!-- Footer -->
    <footer>
        <div class="row">
            <div class="col">
              <ul class="list-inline">
                <li class="list-inline-item"><?php if (!empty($_SERVER['SERVER_SIGNATURE'])) print $_SERVER['SERVER_SIGNATURE']; ?></li>
                <li class="list-inline-item">
                  <button class="btn btn-sm btn-info" data-toggle="modal" data-target="#myModal" data-action="get" data-url="server-status" data-title="Server status">Server status</button>
                  <a target="_blank" title="Open in a new window" href="/server-status" class="btn btn-sm btn-link" role="button"><span class="octicon octicon-link-external" aria-hidden="true"></span></a>
                </li>
                <li class="list-inline-item">
                  <button class="btn btn-sm btn-info" data-toggle="modal" data-target="#myModal" data-action="get" data-url="server-info" data-title="Server info">Server info</button>
                  <a target="_blank" title="Open in a new window" href="/server-info" class="btn btn-sm btn-link" role="button"><span class="octicon octicon-link-external" aria-hidden="true"></span></a>
                </li>
              </ul>
            </div>
        </div>
    </footer>
    <hr>
  </div>
  <!-- /.container -->

  <!-- Modal -->
  <div class="modal fade" id="myModal" tabindex="-1" role="dialog" aria-hidden="true">
  <div class="modal-dialog modal-lg" role="document">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title"></h5>
        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
          <span aria-hidden="true">&times;</span>
        </button>
      </div>
      <div class="modal-body"></div>
      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
        <button type="button" class="btn btn-primary refresh" autocomplete="off"><span class="octicon octicon-sync" aria-hidden="true"></span> Refresh</button>
      </div>
    </div>
  </div>
</div>
  <!-- /.Modal -->

  <!-- Css: Bootstrap -->
  <link
    rel="stylesheet"
    href="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0-beta.2/css/bootstrap.min.css"
    integrity="sha384-PsH8R72JQ3SOdhVi3uxftmaW6Vc51MKb0q5P2rRUpPvrszuE4W1povHYgTpBfshb"
    crossorigin="anonymous">
  <!-- Css: Octicons -->
  <link
    rel="stylesheet"
    href="https://cdnjs.cloudflare.com/ajax/libs/octicons/4.4.0/font/octicons.min.css">
  <!-- jQuery -->
  <script
    src="https://code.jquery.com/jquery-3.2.1.min.js"
    integrity="sha256-hwg4gsxgFZhOsEEamdOYGBf13FyQuiTwlAQgxVSNgt4="
    crossorigin="anonymous"></script>
  <!-- Bootstrap 4 + Popper-->
  <script
    src="https://cdn.jsdelivr.net/npm/popper.js@1.12.9/dist/umd/popper.min.js"
    integrity="sha256-pS96pU17yq+gVu4KBQJi38VpSuKN7otMrDQprzf/DWY="
    crossorigin="anonymous"></script>
  <script src="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0-beta.2/js/bootstrap.min.js"
    integrity="sha384-alpBpkh1PFOepccYVYDB4do5UnbKysX5WZXm3XxPqe5iKTfUKjNkCk9SaVuEZflJ"
    crossorigin="anonymous"></script>
  <!-- Clipboard -->
  <script src="https://cdn.jsdelivr.net/npm/clipboard@1/dist/clipboard.min.js"></script>
  <!-- Terminal -->
  <script
    src="https://cdnjs.cloudflare.com/ajax/libs/jquery.terminal/1.10.1/js/jquery.terminal.js"
    integrity="sha256-/dY7WzTiHP4Z39jXg+KTLMHXKfFqzfWIrdc1M6XZ5rY="
    crossorigin="anonymous"></script>
  <link
    rel="stylesheet"
    href="https://cdnjs.cloudflare.com/ajax/libs/jquery.terminal/1.10.1/css/jquery.terminal.min.css"
    integrity="sha256-IVoPNmmjjN4wZ2OJ2vAPdKX+MHReNkbceOxYnzZEVJE="
    crossorigin="anonymous" />
  <!-- Custom script -->
  <script src="js/app.js"></script>
  <script src="js/unix_formatting.js"></script>
</body>
</html>
