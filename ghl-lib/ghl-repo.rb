module GitHookLib
    ##
    # Useful for extracting information about a git repository.
    ##
    class GitRepo

        @@GIT_GET_GIT_DIR_CMD =     "rev-parse --git-dir"
        
        @@GIT_GET_CUR_BRANCH_CMD =  "rev-parse --abbrev-ref HEAD"
       
        @@GIT_GET_CUR_USR_CMD =     "config --get user.name"
        
        @@GIT_GET_MOD_FLS_CMD =     "status --porcelain --untracked-files=no"
        
        @@GIT_GET_COMMIT_INFO_CMD = "show --format=\"format:%%h%%n%%an%%n%%s\" "\
                                    "--name-only %s..%s"

        @git_dir = nil
        def git_dir
            @git_dir
        end

        @work_tree = nil
        def work_tree
            @work_tree
        end

        @default_commit_msg_file = nil
        def default_commit_msg_file
            @default_commit_msg_file
        end
       
        ##
        # Initialize a new instance of the GitRepo class.
        #
        # git_dir       The path to the repository's git directory.
        #
        # work_tree     The path to the repository's working tree directory.
        #               The working tree directory is not required, and often
        #               does not exist for hosted git repositories.
        ##
        def initialize(git_dir=nil,work_tree=nil)
            if git_dir == nil then
                git_dir = repo_exec(@@GIT_GET_GIT_DIR_CMD)
            end
            @git_dir = trim(git_dir)
            if @git_dir == nil || @git_dir == '' then
                raise "error initializing GitRepo"
            end
            @git_dir = File.expand_path('.', @git_dir)
            debug "@git_dir=#{@git_dir}"

            @default_commit_msg_file = "#{@git_dir}/COMMIT_EDITMSG"
            debug "@default_commit_msg_file=#{@default_commit_msg_file}"

            if work_tree == nil then
                git_dir_name = File.basename(@git_dir)
                if git_dir_name == '.git' then
                    work_tree = File.expand_path('..', @git_dir)
                end
            end
            if work_tree != nil && trim(work_tree) != '' then
                @work_tree = trim(work_tree)
            end
            debug "@work_tree=#{@work_tree}"
        end

        ##
        # Returns the current branch.
        ##
        def current_branch
            return repo_exec(@@GIT_GET_CUR_BRANCH_CMD)
        end

        ##
        # Returns the current user name.
        ##
        def current_user
            return repo_exec(@@GIT_GET_CUR_USR_CMD)
        end

        ##
        # Gets a list of modified files
        ##
        def modified_files
            out = repo_exec(@@GIT_GET_MOD_FLS_CMD)
            lines = out.split(/\r?\n/)
            files = Array.new(lines.length)
            lines.each_index do |x|
                fp = /^\S+\s+(.*)$/.match(trim(lines[x]))[1]
                files[x] = CommitInfoFile.new(fp)
            end
            return files
        end

        ##
        # Returns information about the staged commit.
        ##
        def staged_commit_info(commit_msg=nil)
            return StagedCommitInfo.new(self, commit_msg)
        end

        ##
        # Returns an array of tuples with the following information:
        #
        #   - author's user name
        #   - commit message subject
        #   - the files affected by the commit (this is an array)
        ##
        def commit_info(branch=nil, old_head=nil, new_head=nil)
            out = repo_exec(@@GIT_GET_COMMIT_INFO_CMD, old_head, new_head)
            lines = out.split(/\r?\n/)
            ci_arr = []
            x = 0
            while x < lines.length do
                commit_id = trim(lines[x])
                user =      trim(lines[x+1])
                subject =   trim(lines[x+2])
            
                files = []
                x += 3

                if trim(lines[x]) != '' then
                    while x < lines.length && trim(lines[x]) != '' do
                        files << CommitInfoFile.new(lines[x])
                        x += 1
                    end
                end
                
                x += 1
                ci_arr << CommitInfo.new(commit_id, branch, user, subject, files)
            end
            return ci_arr
        end

        def repo_exec(cmd, *args)
            git_args = []

            if @git_dir != nil then
                git_args << "--git-dir=#{@git_dir}"
            end
            
            if @work_tree != nil then
                git_args << "--work-tree=#{@work_tree}"
            end

            repo_cmd = "git"
            if git_args.length > 0 then
                repo_cmd << " #{git_args.join(' ')}"
            end
            if args.length > 0 then
                debug cmd
                cmd = cmd % args
            end
            repo_cmd << " #{cmd}"
            debug(repo_cmd)
            
            return ghl_exec(repo_cmd)[1]
        end

        private :repo_exec
    end
end
