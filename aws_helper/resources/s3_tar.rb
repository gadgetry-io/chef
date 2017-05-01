#
# Author:: brian.hooper@gadgetry.io
# Cookbook Name:: aws_helper
# Resource:: s3_tar
#
# Copyright:: 2017, Gadgetry, LLC
# www.gadgetry.io
#
# THIS CUSTOM RESOURCE IS DESIGNED TO DOWNLOAD AND/OR EXPLODE A .TAR.GZ ARTIFACT FROM AWS S3
 

# CUSTOM RESOURCE PROPERTIES
property :artifact_name, String, name_property: true
property :version, String, default: '0.0.0'
property :s3_bucket, String
property :s3_remote_path, String
property :aws_region, String, default: 'us-east-1'
property :aws_access_key, String
property :aws_secret_key, String
property :local_owner, String, default: 'root'
property :local_group, String, default: 'root'
property :local_mode, String, default: '0755'
property :local_download_dir, String, default: ""
property :local_extract_dir, String, default: ""
property :local_delete_extract_dir, [TrueClass, FalseClass], default: false
property :local_purge_extract_dir, [TrueClass, FalseClass], default: false

# CUSTOMER RESOURCE NAME
resource_name :s3_tar

# DEFAULT ACTION
default_action :create

action :create do

  # IF DOWNLOAD_DIR IS NOT BLANK OR NULL... SIMPLY DOWNLOAD THE TAR
  if @local_extract_dir != "" || @local_extract_dir != nil

    # DOWNLOAD S3 TAR ARTIFACT
    aws_s3_file "#{local_download_dir}/#{artifact_name}" do
      bucket "#{s3_bucket}"
      remote_path "#{s3_remote_path}/#{artifact_name}"
      region "#{aws_region}"
      owner "#{local_owner}"
      group "#{local_group}"
      mode "#{local_mode}"
      #aws_access_key aws['aws_access_key_id']
      #aws_secret_access_key aws['aws_secret_access_key']
    end

  end

  # IF DELETE_EXTRACT_DIR == TRUE
  # LET'S DELETE THE EXTRACT DIR
  if @local_delete_extract_dir
    execute 'delete_extract_dir' do
      user 'root'
      command "rm -rf #{local_extract_dir}"
    end
  end

  # IF PURGE_EXTRACT_DIR == TRUE
  # LET'S PURGE THE CONTENTS OF THE EXTRACT DIR
  if @local_purge_extract_dir
    execute 'purge_extract_dir' do
      user 'root'
      cwd "#{local_extract_dir}"
      command "rm -rf *"
    end
  end

  # IF EXTRACT_DIR IS NOT BLANK OR NOT NIL 
  # LET'S DOWNLOAD THE TAR, EXTRACT THE TAR, AND REMOVE THE TAR
  if @local_extract_dir != "" || @local_extract_dir != nil

    # CREATE EXTRACT DIRECTORY
    directory "#{local_extract_dir}" do
      owner "#{local_owner}"
      group "#{local_group}"
      mode "#{local_mode}"
      recursive true
      action :create
    end

    # DOWNLOAD S3 TAR ARTIFACT
    aws_s3_file "#{local_extract_dir}/#{artifact_name}" do
      bucket "#{s3_bucket}"
      remote_path "#{s3_remote_path}/#{artifact_name}"
      region "#{aws_region}"
      owner "#{local_owner}"
      group "#{local_group}"
      mode "#{local_mode}"
      #aws_access_key aws['aws_access_key_id']
      #aws_secret_access_key aws['aws_secret_access_key']
    end

    case artifact_name

      when /ta?r?\.?gz$/

        # EXPLODE TAR IN EXTRACT DIR
        execute 'explode_tar_file' do
          user 'root'
          cwd "#{local_extract_dir}"
          command "tar -xzf #{artifact_name} ."
        end

        # CHOWN EXTRACT DIR
        execute 'chown_extract_dir' do
          user 'root'
          command "chown -R #{local.owner}:#{local.group} #{local_extract_dir}"
        end

        # DELETE SOURCE TAR
        execute 'delete_tar_file' do
          user 'root'
          cwd "#{local_extract_dir}"
          command "rm -f #{artifact_name} "
        end

    end

  end

end
