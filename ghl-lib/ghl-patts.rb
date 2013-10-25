module GitHookLib
    
    COMMIT_MSG_AR_OR_JIRA_PATT = 
        /^(Merge branch.*)|(\[((AR\s?\d{6})|(\w{1,}-\d{1,}))\]\s[\w\s]{0,25}(\s-\s.+)?)$/
    
    BRANCH_NAME_PATT = 
        /^(?:refs\/heads\/)?
        (
            master|

            develop|

            (?:(?:release|hotfix)\/
                \d+\.\d+\.\d+(?:-(?!SNAPSHOT)(?:[\w_-]*)))|

            (?:(?:feature|bugfix|attic|support)\/
                (?:(?:AR\d{6})|(?:\w+\d+))(?:-\d+\.\d+\.\d+(?!-SNAPSHOT-))?(?:-[\w_-]*))
        )$/x

end 