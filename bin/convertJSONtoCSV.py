#!/usr/bin/env python

import json
import csv

with open(r"SavedVarOutput.json") as json_file:
    data = json.load(json_file)
    lastUpdate = data['Default']['@LadyWinry']['$AccountWide']["lastUpdate"]


    with open('guild_roster.csv', mode='w') as guild_roster:
        guild_writer = csv.writer(guild_roster, delimiter=',', quotechar='"', quoting=csv.QUOTE_ALL)
        guild_writer.writerow(["lastUpdate",
                                "displayName",
                                "statusString",
                                "status",
                                "rankIndex",
                                "rankName",
                                "secsSinceLogoff",
                                "logoffString"
                                    ])

        for member in data['Default']['@LadyWinry']['$AccountWide']['guildRoster']:
            guild_writer.writerow([lastUpdate,
                                    member['displayName'],
                                    member['statusString'],
                                    member['status'],
                                    member['rankIndex'],
                                    member['rankName'],
                                    member['secsSinceLogoff'],
                                    member['logoffString']
                                    ])
    
    with open('guild_history.csv', mode='w') as guild_history:
        history_writer = csv.writer(guild_history, delimiter=',', quotechar='"', quoting=csv.QUOTE_ALL)
        history_writer.writerow([
                                "timestamp",
                                "displayName",
                                "item",
                                "itemCount",
                                "avgPrice",
                                "eventType",
                                "eventName"
                                ])

        for item in data['Default']['@LadyWinry']['$AccountWide']['guildDepositList']:
            if 'avgPrice' in item:
                avgPrice = item['avgPrice']
            else:
                avgPrice = ""
            history_writer.writerow([
                                    item['timestamp'],
                                    item['displayName'],
                                    item['item'],
                                    item['count'],
                                    avgPrice,
                                    item['eventType'],
                                    item['eventName']
                                    ])

    with open('guild_store.csv', mode='w') as guild_store:
        history_writer = csv.writer(guild_store, delimiter=',', quotechar='"', quoting=csv.QUOTE_ALL)
        history_writer.writerow([
                                "timestamp",
                                "sellerName",
                                "buyerName",
                                "item",
                                "itemCount",
                                "sellPrice",
                                "guildCut",
                                "eventType",
                                "eventName"
                                ])

        for item in data['Default']['@LadyWinry']['$AccountWide']['guildStoreList']:
            #Skip if Guild Trader Bid Events
            if (item['eventType']== 24) or (item['eventType']== 25) or (item['eventType']== 23) :
                continue

            history_writer.writerow([
                                    item['timestamp'],
                                    item['sellerName'],
                                    item['buyerName'],
                                    item['item'],
                                    item['count'],
                                    item['sellPrice'],
                                    item['guildCut'],
                                    item['eventType'],
                                    item['eventName']
                                    ])