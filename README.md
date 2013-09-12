tickets
=======

Redis based support ticket system


---

# Ticket-System

## Redis-DB

### User ( HASH )

* Name
* email
* pushkey
* Rolle ( USER, DEVELOPER )
* Status ( erriechbar, gesperrt )
* NotifyCount
* ReactionCount
* TicketCount

### Ticket ( KEY )

* author
* title
* description
* workflowstate
  *	new
  * rejected
  * accepted
  * working
  * waitingforreply
  * solution
* starttime
* acceptedtime
* solutiontime
* github_issue_id

### Comments ( ZSET )

* ticket_id
* type (text,sys)
* time
* content
* author