class RenameVeyonHostWebapiPortToServicePort < ActiveRecord::Migration[7.2]
  def up
    return unless table_exists?(:veyon_hosts)

    if column_exists?(:veyon_hosts, :webapi_port) && !column_exists?(:veyon_hosts, :service_port)
      remove_index :veyon_hosts, column: [:host, :webapi_port], if_exists: true
      rename_column :veyon_hosts, :webapi_port, :service_port
    end

    change_column_default :veyon_hosts, :service_port, 11100 if column_exists?(:veyon_hosts, :service_port)
    add_index :veyon_hosts, [:host, :service_port], unique: true, if_not_exists: true
  end

  def down
    return unless table_exists?(:veyon_hosts)

    remove_index :veyon_hosts, column: [:host, :service_port], if_exists: true
    change_column_default :veyon_hosts, :service_port, 11080 if column_exists?(:veyon_hosts, :service_port)

    if column_exists?(:veyon_hosts, :service_port) && !column_exists?(:veyon_hosts, :webapi_port)
      rename_column :veyon_hosts, :service_port, :webapi_port
    end

    add_index :veyon_hosts, [:host, :webapi_port], unique: true, if_not_exists: true if column_exists?(:veyon_hosts, :webapi_port)
  end
end
