Redirector
==========

Nginx configuration and supporting tools and tests for the redirector,
keeping our old websites on the internet, because [cool URIs don't change][cool].

[cool]:http://www.w3.org/Provider/Style/URI.html


Adding a new website
--------------------

Add the site to sites.csv.

Site: this is the name of the site, eg 'communities' for the site `www.communities.gov.uk`
Redirected: this will be N. When the mappings are correct and finalised, you will change this to Y.
Old department homepage: e.g. http://www.communities.gov.uk
New department homepage: e.g. communities (NB. Is this always the name? Can we then leave it out? Or, should we actually put, on the 410 pages, the new URL, e.g https://www.gov.uk/government/organisations/department-for-communities-and-local-government)
Redirection date: the date the site will be switched over (this is for information on 410 pages)
National Archives timestamp: this is required for the link on the 410 page

**n.b.** during these instructions WEBSITE should be replaced with the name of
the site being added (eg 'communities' for the site ).

### Create the mappings CSV
    
    source tools/generate_configuration.sh 
    generate_mappings_source $name $old_department_homepage $new_department_homepage

This creates a file in data/mappings with four columns - Old Url, Status (i.e. 301 or 410), New Url (if 301), Archive Link (e.g. for friendly URLs).

It also creates a redirect from the old department homepage to the new one.

This is the file that you should populate with your mappings. It should be sorted on the Old Url column (this makes diffs between commits more readable).

### Create the site in the repository

1.  In the `redirector` directory, create a new configuration file containing
    the nginx server block(s) needed for the site.

1.  Add WEBSITE to `sites.sh`.

1. Create the static assets

    source tools/generate_static_assets.sh
    generate_404_page $department_name $redirection_date $department_full_name $new_department_homepage
    generate_410_page $department_name $redirection_date $department_full_name $new_department_homepage $national_archives_timestamp $old_website_address

Also copy gone.css.

### Create the required tests

#### Valid Lines

Add a valid lines test script:

    source tools/generate_tests.sh
    generate_valid_lines_test $Name_of_site

$Name_of_site here should be with an initial capital, e.g. Directgov.

This is required because jenkins.sh tests all the mappings before attempting to build. 

#### Subset test 

This is a quick test of the most important urls which will be run on every deployment.

It doesn't need to be 250, and it can just be a random sample, but ideally it would be the top 10% or so mappings in terms of importance.

1. Create a sample mappings file containing up to 250 urls, e.g. `tests/integration/test_data/top_250_WEBSITE_urls.csv`. 
2. Create the test script, e.g. `tests/integration/sample/top_250_WEBSITE.t` you can base it on `tests/integration/sample/top_250_directgov.t`

You can run this test using `prove -l tests/integration/sample/top_250_WEBSITE.t` but it will not pass until the redirector is deployed.

#### Complete test

This is a full integration test which is run on a nightly basis

Create test scripts at `tests/integration/ratified/WEBSITE/` you can base them on the tests in `tests/integration/ratified/directgov/`

### Dry-run the post-commit build

Run `bash jenkins.sh` before committing and pushing the new site to confirm
that it doesn't break, which would stop anyone from deploying.

The last line output by `jenkins.sh` is "Redirector build succeeded."

### Deploy the redirector to preview

A jenkins commit will kick off the Redirector build, followed by the Redirector-deploy (which only deploys to preview), 
then followed by the Redirector-Integration-Subset. 

You should make sure that these tests all pass before you deploy to production. 

### Deploy the redirector to production

You must deploy the redirector to production before altering puppet.

There is no release tag - all that is required for the production deploy is the build number of the latest Redirector job.

### Add the website to puppet

Add the new config file(s) to the `puppet` repository, in the file
`modules/govuk/manifests/apps/redirector.pp`:

    file { '/etc/nginx/sites-enabled/WEBSITE':
      ensure => link,
      target => '/var/apps/redirector/WEBSITE.conf',
      notify => Class['nginx::service'],
    }

### Test against preview

Deploy puppet to preview to activate the website's configuration with nginx.

Run the subset and full integration tests against preview to confirm that
all links are actually being redirected.

    export DEPLOY_TO=preview
    prove -l tests/integration/sample/top_250_WEBSITE.t
    prove -l tests/integration/ratified/WEBSITE/

### Test against production

Once the tests pass in preview, deploy puppet and run the tests against
production.

    export DEPLOY_TO=production
    prove -l tests/integration/sample/top_250_WEBSITE.t
    prove -l tests/integration/ratified/WEBSITE/

Once they pass, you can now proceed to switching the domains to the 
redirector.

When mappings are finalised
---------------------------

When all the mappings are complete, correct and passing the integration tests, you can make them finalised. 

This entails moving the site in sites.sh from IN_PROGRESS_SITES to REDIRECTED_SITES and creating the regression tests, and setting redirected to Y in sites.csv.

To create the regression test:

    source tools/generate_tests.sh
    generate_regression_test $Name_of_site

$Name_of_site here should be with an initial capital, e.g. Directgov.


Note that the tests in redirects/ are slightly different to the integration tests - the redirect tests call the method test_finalised_redirects rather than test_closed_redirects. This means that they do not fail if the 301 location is not a 200. Redirects to non-GOV.UK sites are tested for a successful response (i.e. 200, 301, 302 or 410) and redirects to GOV.UK are chased (max 3 redirects) to ensure they end up eventually at a 200 or 410.

This is so changing slugs that are handled correctly do not break the regression tests. Lists of chased redirects are output by the Jenkins job so these can easily be updated.
