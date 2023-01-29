<?php
// Icinga Web 2 Docker image | (c) 2020 Icinga GmbH | GPLv2+

namespace Icinga\Module\Dockerentrypoint\Clicommands;

use Icinga\Application\Config;
use Icinga\Application\Icinga;
use Icinga\Authentication\User\UserBackend;
use Icinga\Cli\Command;
use Icinga\Data\Filter\Filter;
use Icinga\Data\ResourceFactory;
use Icinga\Module\Setup\Utils\DbTool;
use Icinga\Util\Json;
use PDOException;

class DbCommand extends Command
{
    public function backendsAction()
    {
        $resources = [];
        $config = Config::app();

        if ($config->get('global', 'config_backend') === 'db') {
            $configResource = $config->get('global', 'config_resource');

            if ($configResource !== null) {
                $resources[$configResource] = null;
            }
        }

        foreach (['authentication', 'groups'] as $file) {
            foreach (Config::app($file) as $backend) {
                if ($backend->backend === 'db') {
                    $resource = $backend->resource;

                    if ($resource !== null) {
                        $resources[$resource] = null;
                    }
                }
            }
        }

        ksort($resources);

        echo Json::encode(array_keys($resources));
    }

    public function initializedAction()
    {
        echo (int) (array_search('icingaweb_group', $this->getDb()->listTables(), true) !== false);
    }

    public function initAction()
    {
        $db = $this->getDb();

        $db->import(
            Config::module('setup')
                ->get('schema', 'path', Icinga::app()->getBaseDir('schema')) . "/{$db->dbType}.schema.sql"
        );
    }

    public function userAction()
    {
        $username = $this->params->getRequired('name');
        $password = getenv('PASSWORD');
        $backend = UserBackend::create($this->params->getRequired('backend'));

        if ($backend->select()->where('user_name', $username)->count() > 0) {
            $backend->update('user', ['password' => $password], Filter::where('user_name', $username));
        } else {
            $backend->insert('user', [
                'user_name' => $username,
                'password'  => $password,
                'is_active' => 1
            ]);
        }
    }

    /**
     * @return DbTool
     */
    protected function getDb()
    {
        $config = ResourceFactory::getResourceConfig($this->params->getRequired('resource'))->toArray();
        $type = isset($config['db']) ? $config['db'] : 'mysql';

        if (! isset($config['port'])) {
            switch ($type) {
                case 'mysql':
                    $config['port'] = 3306;
                    break;
                case 'pgsql':
                    $config['port'] = 5432;
            }
        }

        for ($i = 0; $i < 100; ++$i) {
            try {
                (new DbTool($config))->checkConnectivity();
                break;
            } catch (PDOException $e) {
                fprintf(
                    STDERR, "[%s] [docker_entrypoint:error] [pid %d] DOCKERE: Can't connect to database: %s\n",
                    date('D M j H:i:s.u Y'), getmypid(), $e->getMessage()
                );

                sleep(3);
            }
        }

        $db = new DbTool($config);
        $db->connectToDb();
        $db->dbType = $type;
        return $db;
    }
}
