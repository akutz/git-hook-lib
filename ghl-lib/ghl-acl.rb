module GitHookLib

    ##
    # An access control list for git objects.
    ##
    class Acl
        @allow = nil
        def allow
            @allow
        end
        @branch_patt = nil
        def branch_patt
            @branch_patt
        end
        @user_patt = nil
        def user_patt
            @user_patt
        end
        @path_patt = nil
        def path_patt
            @path_patt
        end
      
        def initialize(branch, users='.*', path='.*')
            @allow = true
            @branch_patt = Regexp.new("^(?:#{branch})$")
            @user_patt = Regexp.new("^(?:#{users})$")
            @path_patt = Regexp.new("^(?:#{path})$")
        end

        def inspect
            "Acl[" +
                "allow=#{@allow}," + 
                "branch_patt='#{@branch_patt.source}'," + 
                "user_patt='#{@user_patt.source}'," +
                "path_patt='#{@path_patt.source}'" + 
            "]"
        end
    end

    ##
    # A utility class used for reading ACL files.
    ##
    class AclUtils
        
        ##
        # Parses an array of ACLs from an ACL file.
        ##
        def self.parse_acls(acl_file)
            lines = IO.readlines(acl_file).reject{|line|is_line_valid?(line)}
            acls = Array.new(lines.length + 1 )
            lines.each_index do |x|
                branch, users, path = lines[x].strip.split(',')
                acls[x] = Acl.new(branch, users, path)
            end

            # Always add two super-users named git and root.
            acls[acls.length - 1] = Acl.new(".*", "git|root")
            
            return acls
        end

        ##
        # Returns a flag indicating whether or not the line is a valid ACE.
        # Empty lines and lines beginning with a # symbol are ignored.
        ##
        def self.is_line_valid?(line)
            return line == nil || line.start_with?('#') || line.strip == ''
        end

        ##
        # Returns a flag indicating whether or not the provided ACLs allow
        # the specified user to modify the specified path for the specified
        # branch.
        ##
        def self.is_allowed?(acls, branch, user, files=nil)
            allowed = false
            
            acls.each do |a|
                
                bp = a.branch_patt
                up = a.user_patt
                pp = a.path_patt
                
                if a.allow && matches?(branch, bp) && matches?(user, up) then
                    
                    # Once a branch and user matches then that's the applied 
                    # ACE, so allowed access is assumed from this point forward
                    # until proven otherwise by file restrictions.
                    allowed = true

                    if files != nil
                        files.each do |f|
                            if matches?(f.path, pp) then
                                f.writeable = true
                            else
                                f.writeable = false
                                allowed = false
                                debug "denied: #{user}@#{branch}:#{f.path}"
                            end
                        end
                    end
                    
                    break
                end

            end

            if allowed then
                debug "allowed: #{user}@#{branch}"
            else
                debug "denied: #{user}@#{branch}"
            end

            return allowed
        end
    end
    
end