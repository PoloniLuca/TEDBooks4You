const connect_to_db = require('./db');
const User = require('./Talk');
const request = require('request');
const repl = require('repl');
repl.ignoreUndefined=true;

module.exports.get_related_books = (event, context, callback) => {
    context.callbackWaitsForEmptyEventLoop = false;
    console.log('Received event:', JSON.stringify(event, null, 2));
    
    let body = {};
    if (event.body) {
        body = JSON.parse(event.body);
    }
    
    if (!body.id) {
        if (event.id) {
            body.id = event.id;
        } else {
            callback(null, {
                statusCode: 500,
                headers: { 'Content-Type': 'text/plain' },
                body: 'Could not fetch the user. ID is missing.'
            });
            return;
        }
    }

    connect_to_db().then(() => {
        console.log('=> Searching for user');

        User.findOne({ _id: body.id })
            .then(user => {
                if (!user) {
                    throw new Error('User not found');
                }
               
                // Verifica la presenza di all_tags_info nell'oggetto user
                const id = user._id;
                console.log('User:', JSON.stringify(id, null, 2).substring(0, 100));
                
                const allTagsInfo = user.all_tags_info;
                
                if(allTagsInfo){
                    console.log("esiste allTagsInfo");
                }else{
                    console.log("All Tags Info:", JSON.stringify(allTagsInfo, null, 2));
                }
                
                if (allTagsInfo) {
                    const tagsWithCount = allTagsInfo.forEach(tagInfo => {
                        console.log("tag:", tagInfo.tag);
                        console.log("tag_count:", tagInfo.tag_count);
                        // Esegui le operazioni necessarie qui
                        tag: tagInfo.tag;
                        count: tagInfo.tag_count;
                    });
                } else {
                    console.log("allTagsInfo is undefined.");
                }
                
                const tagsWithCounts2 = allTagsInfo.map(tagInfo => ({
                    tag: tagInfo.tag,
                    count: tagInfo.tag_count
                }));
                
                console.log("tagsWithCounts:", tagsWithCounts);

                const sortedTags = tagsWithCounts.sort((a, b) => b.count - a.count);
                const topTags = sortedTags.slice(0, Math.min(10, sortedTags.length)).map(tagInfo => tagInfo.tag);
                
                console.log('Calling Google Books API for tags:', topTags);

                const booksPromises = topTags.map(tag => {
                    const url = `https://www.googleapis.com/books/v1/volumes?q=${tag}&maxResults=1`;
                    return new Promise((resolve, reject) => {
                        request(url, (error, response, body) => {
                            if (error) {
                                reject(error);
                            } else if (response.statusCode !== 200) {
                                reject(new Error(`Google Books API returned status code ${response.statusCode}`));
                            } else {
                                const data = JSON.parse(body);
                                if (data && data.items && data.items.length > 0) {
                                    resolve({
                                        title: data.items[0].volumeInfo.title,
                                        authors: data.items[0].volumeInfo.authors,
                                        description: data.items[0].volumeInfo.description
                                    });
                                } else {
                                    resolve(null);
                                }
                            }
                        });
                    });
                });

                Promise.all(booksPromises)
                    .then(books => {
                        const filteredBooks = books.filter(book => book !== null);
                        
                        callback(null, {
                            statusCode: 200,
                            body: JSON.stringify({ books: filteredBooks })
                        });
                    })
                    .catch(err => {
                        throw new Error(`Error querying Google Books API: ${err.message}`);
                    });
            })
            .catch(err => {
                callback(null, {
                    statusCode: 404,
                    headers: { 'Content-Type': 'text/plain' },
                    body: err.message
                });
            });
    });
};
