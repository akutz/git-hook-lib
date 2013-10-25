module GitHookLib

    ##
    # The base class for the ServerSideHooks and ClientSideHooks classes.
    ##
    class HookService
        @@SPRINTF_LEN = 50

        @git_repo
        @ghl_dir

        def initialize(ghl_dir, git_repo)
            @ghl_dir = ghl_dir
            @git_repo = git_repo
        end

        def self.instance(ghl_dir, git_repo, hook_type)
            if hook_type == "server" then
                return ServerSideHookService.new(ghl_dir, git_repo)
            else
                return ClientSideHookService.new(ghl_dir, git_repo)
            end
        end

        ##
        # Abstract method
        ##
        def exec_hook(hook_name, hook_args)
        end

        def spf_slice(str)
            return str != nil && str.length > @@SPRINTF_LEN ? 
                str.slice(0, @@SPRINTF_LEN) : str
        end

        def acl_file()
            return "%s/acl.ghl" % @ghl_dir
        end

        def sprintf_ci(ci, print_all_files=false)

            msg = ""

            if ci.commit_id != nil then
                msg <<      "   Commit:   #{ci.commit_id}\n"\
            end

            msg <<          "   Branch:   #{ci.branch}\n"\
                            "   Author:   #{ci.user}\n"
                            
            if ci.subject != nil then
                msg <<      "  Subject:   #{spf_slice(ci.subject)}\n"
            end

            print_files = print_all_files ? true : 
                ci.files == nil ? false : ci.files.count{|f|!f.writeable} > 0

            if  !print_files then return msg << "\n" end
                
            if ci.files != nil && ci.files.length > 0 then
                first_file = true
                ci.files.each do |f|
                    if print_all_files || !f.writeable then
                        if first_file then
                            first_file = false
                            msg << "    Files:   #{spf_slice(f.path)}\n"
                        else
                            msg << "             #{spf_slice(f.path)}\n"
                        end
                    end
                end
            end

            return msg
        end

        def validate_branch_name(branch)
            if ! BranchUtils.is_valid_name?(branch)
                abort COMMIT_ABORTED_PRE_COMMIT_BRANCH_NAME_MSG % branch
            end
        end

        def validate_commit_messages(commit_infos)
            if commit_infos.is_a?(CommitInfo) then 
                commit_infos = [commit_infos] 
            end
            errors = []
            commit_infos.each do |ci|
                debug "ci.subject=#{ci.subject}"
                if ! CommitMessageUtils.is_valid?(ci.subject)
                    errors << sprintf_ci(ci, true)
                end
            end
            if errors.length > 0 then
                abort COMMIT_MESSAGE_ABORTED_ERROR % errors.join("\n")
            end
        end

        def validate_branch_permissions(commit_infos)
            if commit_infos.is_a?(CommitInfo) then 
                commit_infos = [commit_infos] 
            end
            acls = AclUtils.parse_acls(acl_file)
            errors = []
            commit_infos.each do |ci|
                if ! AclUtils.is_allowed?(acls, ci.branch, ci.user, ci.files) then
                    errors << sprintf_ci(ci)
                end
            end
            if errors.length > 0 then
                abort COMMIT_ABORTED_INSUFFICIENT_PERMS_MSG % errors.join("\n")
            end
        end
    end

    ##
    # Contains methods that map to git server-side hooks.
    ##
    class ServerSideHookService < HookService
        ##
        # Executs a server-side hook.
        ##
        def exec_hook(hook_name, hook_args)
            case hook_name
                when 'update'
                    # hook_args[0] - branch name
                    # hook_args[1] - old head commit id
                    # hook_args[2] - new head commit id
                    update(hook_args[0], hook_args[1], hook_args[2])
            end
        end

        def update(branch, old_head, new_head)
            # Remove the refs/heads/ prefix if it exists.
            branch = branch.gsub(/^refs\/heads\//, '')

            # Validate the branch name.
            validate_branch_name(branch)
            
            # Get the commit information using the new commit head's ID.
            commit_infos = @git_repo.commit_info(branch, old_head, new_head)

            # Validate the commit message(s).
            validate_commit_messages(commit_infos)

            # Validate the branch permissions.
            validate_branch_permissions(commit_infos)
        end
    end

    ##
    # Contains methods that map to git client-side hooks.
    ##
    class ClientSideHookService < HookService
        ##
        # Executs a client-side hook.
        ##
        def exec_hook(hook_name, hook_args)
            case hook_name
                when 'pre-commit'
                    pre_commit
                when 'commit-msg'
                    # hook_args[0] - commit msg file
                    commit_msg(hook_args[0])
            end
        end

        ##
        # Returns a flag indicating whether the commit message is valid.
        #
        # commit_msg_file The path to the file that contains the commit message.
        ##
        def commit_msg(commit_msg_file)
            # Validate the commit message
            validate_commit_messages(
                @git_repo.staged_commit_info(get_commit_msg(commit_msg_file)))
        end

        ##
        # Returns a flag indicating whether the commit should proceed.
        ##
        def pre_commit()
            # Validate the branch name
            validate_branch_name(@git_repo.current_branch)

            # Validate branch permissions
            validate_branch_permissions(@git_repo.staged_commit_info)
        end

        ##
        # Gets the commit message from the file if it exists; otherwise nil.
        ##
        def get_commit_msg(commit_msg_file=nil)
            if commit_msg_file == nil then return nil end
            commit_msg_file = File.expand_path('.', commit_msg_file)
            debug "commit_msg_file=#{commit_msg_file}"
            if !File.exists?(commit_msg_file) then return nil end
            return trim(File.read(commit_msg_file))
        end
    end
end