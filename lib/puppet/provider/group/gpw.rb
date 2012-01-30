require 'puppet'
require 'etc'
require 'fileutils'

Puppet::Type.type(:group).provide(:gpw) do
  desc "Group management using pw."

  commands(
    :pw => "/usr/sbin/pw",
  )

  has_feature :manages_members

  def create
    cmd = [command(:pw), "groupadd"]
    if gid = @resource.should(:gid)
      unless gid == :absent
        cmd << '-g' << gid
      end
    end
    cmd << @resource[:name]
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
    cmd = [command(:pw), "groupmod"]
    cmd << '-M' << value.join(',') << @resource[:name]
    execute(cmd)
  end

end
