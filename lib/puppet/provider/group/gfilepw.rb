require 'puppet'
require 'etc'
require 'fileutils'

Puppet::Type.type(:group).provide(:gfilepw) do
  desc "Group management using pw."

  commands(
    :pw => "/usr/sbin/pw"
  )

  has_feature :manages_members

  def create
    cmd = [command(:pw), "groupadd"]
    cmd << @resource[:name]
    if gid = @resource.should(:gid)
      unless gid == :absent
        cmd << '-g' << gid
      end
    end
    execute(cmd)
    if members = @resource.should(:members)
      unless members == :absent
        self.members=(members)
      end
    end
  end

  def delete
    cmd = [command(:pw), "groupdel"]
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
    cmd = [command(:pw), "groupmod"]
    cmd << @resource[:name] << '-g' << gid
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
    begin
      groupfile_path_tmp = '/etc/group.puppettmp'
      groupfile_path = '/etc/group'
      groupfile_tmp = File.open(groupfile_path_tmp, 'w')
      groupfile = File.foreach(groupfile_path) do |line|
        if groupline = line.match(/^#{@resource[:name]}:[x*]?:[0-9]+:/)
          Puppet.debug "Writing members " << value.join(',') << " to " << groupfile_path_tmp
          groupfile_tmp.puts groupline[0] + value.join(',')
        else
          groupfile_tmp.puts line
        end
      end
      groupfile_tmp.fsync
      groupfile_tmp.close 
      Puppet.debug "Saving " << groupfile_path_tmp << " to " << groupfile_path
      File.rename(groupfile_path_tmp, groupfile_path)
    rescue Exception => e
      FileUtils.deleteQuietly(groupfile_tmp)
      raise Puppet::Error.new(e.message)
    end
  end

end
