# Customer Relationship Management

A small set of CRM tools written in Lua. Currently packaged as a read-eval-print loop. As it matures and the code becomes more thoughtfully arranged, it's my hope that the actual REPL can be cut down to 500 lines of code. Keeping all of the good stuff in a set of libraries. 

Because in theory it ought to be equally useful as a library for a lightweight CRM interface, a web API, or for writing one-off scripts. And not just limited to business-related applications. 

## Why

Most CRM's work fine, but not great. My experience with Salesforce was terrible. Apparently Camping World couldn't afford the extensions or some attention to detail. It was about as useful as a spreadsheet. No more no less. 

And it seems like any CRM administered by a business has all these little frustrations that add up to one big headache. Eventually it prevents the individual from taking initiative or being creative. Or as it was at camping world simple tasks took much too long.

It comes down to having control over the data. While a saleman shouldn't have the authority to bin all of the customer data the company has acquired, he should be able to arrange it as he sees fit.

Especially for searching. Even with a monolithic database of dead leads that are not notated, an ambitious new salesman could filter for people he might have an edge with. 

Plus every CRM suite or package seems to have a lot of overhead. Whether it's clunky webpages, or the costs, or its inflexibility, nothing publicly available seems to be truly minimal.

So that's the bulk of my motivation. Programming (despite past efforts) is something I do on the side. So the work I put into this is very slow and amateurish. Which is why my sales job had to end for me to have the time and patience to build this. But this may be one of those cases where persistence pulls through. My hopes for this humble program are that it will see many different iterations, many of which will accompany myself through life, and maybe assist others at some point or another. 

## What

At its core this is just a linked list, stored in a binary file. Forth inspired. 
The idea is a structure that is easy to traverse, while allowing for multiple structures, and being data-agnostic. So that pictures could easily be added, information can be hierarchical, maybe eventually everything will be linked in a way that allows for computer-assisted connections to be discovered.  

In practice I'm very happy with a simple and effective tool that can exist on my laptop, on a remote server, or carried around on a thumb drive. Where the data is owned by me, not bloated, easy to reverse engineer, and can easily be exported into different formats.

## When 

Well now that I'm returning to work on this a bit more, it's interesting to speculate when it'll become polished enough to want to share with others. Honestly if I were to drop everything and resctructure it right now, I probably would want to show it off. But I really need to rethink the interface and how the libraries should be arranged before that happens. 

## Who

In the short term this is for people like myself. Comfortable with a text-based interface and who find a minimal solution desirable. 
Especially those who want something that's extendable. Because let's face it, who is going to spend time learning sql, web stuff, php, all to just extend an existing open source CRM? Some people might, for myself though, it's just too much. 

## Lofty Ambitions
* Calendar system
  * ability to script future events
  * the ability to have a full picture of a strategy. 
    Both for cold calling, and followup. 
* Simple enough REPL (and good enough libraries)
  So that any user can easily extend it, or rewrite it to suite
  his needs. 
* Support for binary files packed into the database: jpg/png, mp3, txt, etc.
* A web frontend. 
  * anyone can get a cheap VPS and fire up the program. 
  * It might be simplistic for security reasons
  * But one could easily log in from ssh for more control. 
    Or easily add another function. 
* Perhaps an additional coaching script. 
  * Where you specify your own goals and affirmations. 
  * Maybe you include an ideal pre-game routine. 

## Other Random Ideas
  * Document generation is probably unnecessary. 
    It could easily be scripted in, but most people would just
    keep a template on hand. 
  * App integration. 
    * mostly useless, surely a csv can export everything you need
    * The only exception may be for a dialer app. 
      Could send all phone numbers to dialer until one picks up,
      Then it returns the number to our app as needed to pull up
      all the info and be available for notes. 
  * Frustrating that there aren't anymore websites that
    let you swap contacts for other contacts. 
    Perhaps there would be some way to restructure this format
    to enable collaboration.
      * Could make friends with 3 other salesmen
      * We each select 250 contacts that we have, 
        and share the names/roles only and area codes
        to verify to one another the quality of the data. 
      * Then we pull this list into a new database, leaving
        behind the personal notes and events. 
  * Using recorded events, notes, etc. Have a Dashboard script
    That will construct basic statistics. 
    Could be used to keep an active closing ratio, among others. 
