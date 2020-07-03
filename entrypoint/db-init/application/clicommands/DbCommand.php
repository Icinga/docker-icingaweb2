<?php

namespace Icinga\Module\Dockerentrypoint\Clicommands;

use Icinga\Application\Config;
use Icinga\Application\Icinga;
use Icinga\Cli\Command;
use Icinga\Data\ResourceFactory;
use Icinga\Module\Setup\Utils\DbTool;
use Icinga\Util\Json;

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
                ->get('schema', 'path', Icinga::app()->getBaseDir('etc/schema')) . "/{$db->dbType}.schema.sql"
        );
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

        $db = new DbTool($config);
        $db->connectToDb();
        $db->dbType = $type;
        return $db;
    }
}
