# PDX Trees for iOS

Last updated: 2011-06-24

About the project: [PDX Trees](http://pdxtrees.org)

The latest release is available on the [App Store](http://itunes.apple.com/us/app/pdx-trees/id397678249?mt=8).

## Running the app

There are a few image files that are gitignored for licensing reasons, and the RESTConstants.m file is gitignored because it has passwords in it. At some point, I'll probably add a build script to copy/create these files automatically if they don't exist. For now, here's how to fix/avoid build errors:

* Make copies of the lower-resolution image files, and rename them based on the @2x convention used for Retina-scale images.
* Create a RESTConstants.m file, using the template in the RESTConstants.h file. At the moment, you do still need an account to access photo info, but not the actual photos. This will change soon when I migrate to CouchDB. Until then, if you want an account, email me and I'll send you one. 

## Roadmap

Planned for v1.1:

* DONE: Fix subtitle on callouts
* DONE: Fix host reachability check that can cause delay when loading detail screen
* DONE: View more than six images/refactoring gallery code
* DONE: Tap thumbnail to go to a specific image, not just the first one
* DONE: Refactored some of the dubious, last-minute solutions implemented to hit the Civic Apps deadline

* TESTING: Upload images to CouchDB instead of Django
* TESTING: Improved gallery controller, with better memory handling
* Better upload management, including bigger progress HUD and timeout
* Different texture on image upload screen
* Don't store photos in Documents folder (ticket 234)
* Add credits to the caption (requires API change)
* General pre-release testing

Maybe for v1.1:

* Add new trees to database, and make corrections (pending availability of data)
* List/organize trees by type
* Tree search
* Share via Twitter and Facebook (website launch is a possible dependency for this one)

A little further off:

* An upload queue for sending larger photos when WiFi is available
* A Universal app, with an iPad-specific layout
* iOS 5 compatibility and testing

## Known Issues

The first release of this app was kind of an organic, design-as-you-go project. I was trying to make it across the Civic Apps finish line last fall, and it shows. Whenever I hit a pothole, I didn't repair it, I filled it with sand. Some of those potholes have been repaired since, some are still on the to-do list.

As of June 2011, this is living code moving towards 1.1 release in a matter of weeks. That means that a lot of  implementation details are in flux, especially code related to image uploads and downloads. I've implemented some of the new code paths in parallel so I can do a/b testing in the field (for example, the switch in the ImageSubmitViewController determines whether the upload goes to Couch or Django) and obviously that will be cleaned up before submitting 1.1 to the App Store.

## Dependencies

This project uses [json-framework](http://code.google.com/p/json-framework/) and [ASIHTTPRequest](http://allseeing-i.com/ASIHTTPRequest/) and [MBProgressHUD](https://github.com/matej/MBProgressHUD), which are included in the project for convenience.

## License and Copyright

**Modified BSD:**
http://opensource.org/licenses/bsd-license

Copyright (c) 2011, Elsewise LLC
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
* Neither the name of Elsewise LLC nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Terms of Use For Data

Use of included data binds you to the Civic Apps Terms of Use. See included document titled:

* pdxTreesCivicAppsTermsOfUse.txt

For more information, please visit the [Civic Apps website](http://www.civicapps.org).