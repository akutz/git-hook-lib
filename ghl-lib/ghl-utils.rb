module GitHookLib

    def xargs(*args)
        if args == nil then return nil end
        if args.length == 1 and args[0].is_a?(Array) then return args[0] end
        return args
    end

    def matches?(str, rx)
        if str == nil && rx == nil then
            debug "'' matches ''"
            return true
        end

        if str == nil then
            debug "!matches '#{rx.source}' bc/ str=nil"
            return false
        end

        m = rx.match(str)
        if m == nil then
            debug "'#{str}' !matches #{rx.source}'"
            return false
        end

        debug "'#{str}' matches #{rx.source}"
        return true
    end

    ##
    # Contains methods to assist in parsing and verifying commit messages.
    ##
    class CommitMessageUtils
        ##
        # Returns a flag indicating whether or not the given commit message
        # matches the message pattern COMMIT_MSG_AR_OR_JIRA_PATT.
        ##
        def self.is_valid?(commit_msg)
            return matches?(commit_msg, COMMIT_MSG_AR_OR_JIRA_PATT)
        end
    end

    ##
    # Contains methods to verify branch names and permissions.
    ##
    class BranchUtils
        ##
        # Returns a flag indicating whether or not the given branch name
        # matches the approved branch name pattern.
        ##
        def self.is_valid_name?(branch_name)
            return matches?(branch_name, BRANCH_NAME_PATT) &&
                !branch_name.end_with?('-SNAPSHOT')
        end
    end

end