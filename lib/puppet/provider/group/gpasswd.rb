require 'puppet'
require 'etc'
require 'fileutils'

Puppet::Type.type(:group).provide(:gpasswd) do
  desc "Group management using gpasswd and getent."

  commands(
    :groupadd => "/usr/sbin/groupadd",
    :groupdel => "/usr/sbin/groupdel",
    :groupmod => "/usr/sbin/groupmod",
    :getent   => "/usr/bin/getent"
  )

  optional_commands :gpasswd => "/usr/bin/gpasswd"
  confine :operatingsystem => [ :ubuntu, :solaris ]
  has_feature :manages_members

  def create
    cmd = [command(:groupadd)]
    if gid = @resource.should(:gid)
      unless gid == :absent
        cmd << '-g' << gid
      end
    end
    cmd << "-o" if @resource.allowdupe?
    cmd << @resource[:name]
    execute(cmd)
    if members = @resource.should(:members)
      unless members == :absent
        self.members=(members)
      end
    end
  end

  def delete
    cmd = [command(:groupdel)]
    cmd << @resource[:name]
    execute(cmd) 
  end

  def exists?
    begin
      @group ||= Etc.getgrnam @resource[:name]
      return true
    rescue
      return false
    end
  end 

  def gid
    @group ||= Etc.getgrnam @resource[:name]
    return @group.gid
  end

  def gid=(gid)
    cmd = [command(:groupmod)]
    cmd << "-o" if @resource.allowdupe?
    cmd << '-g' << gid << @resource[:name]
    execute(cmd) 
  end

  def name
    @group ||= Etc.getgrnam @resource[:name]
    return @group.name
  end

  def members
    @group ||= Etc.getgrnam @resource[:name]
    return @group.mem
  end

  def members=(value)
    case Facter.value(:operatingsystem)
    when "Ubuntu"
      cmd = [command(:gpasswd)]
      cmd << '-M' << value.join(',') << @resource[:name]
      execute(cmd)
    else
      begin
        groupfile_path_new = '/etc/group.puppettmp'
        groupfile_path_old = '/etc/group'
        groupfile_new = File.open(groupfile_path_new, 'w')
        groupfile_old = File.foreach(groupfile_path_old) do |line|
          if groupline = line.match(/^#{@resource[:name]}:[x*]?:[0-9]+:/)
            Puppet.debug "Writing members " << value.join(',') << " to " << groupfile_path_new
            groupfile_new.puts groupline[0] + value.join(',')
          else
            groupfile_new.puts line
          end
        end
        Puppet.debug "Saving " << groupfile_path_new << " to " << groupfile_path_old
        FileUtils.mv(groupfile_path_new, groupfile_path_old)
      rescue Exception => e
        FileUtils.deleteQuietly(groupfile_new)
        raise Puppet::Error.new(e.message)
      end
    end
  end
end
