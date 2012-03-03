require 'puppet'
require 'etc'
require 'fileutils'

Puppet::Type.type(:group).provide(:ggroupadd) do
  desc "Group management using groupmod and gpasswd."

  commands(
    :groupadd => "/usr/sbin/groupadd",
    :groupdel => "/usr/sbin/groupdel",
    :groupmod => "/usr/sbin/groupmod",
    :gpasswd  => "/usr/bin/gpasswd"
  )

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
    cmd = [command(:gpasswd)]
    cmd << '-M' << value.join(',') << @resource[:name]
    execute(cmd)
  end
end
