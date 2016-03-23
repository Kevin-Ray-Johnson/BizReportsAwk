#!/usr/bin/gawk -f

BEGIN{
    FS = ","
    PATH = ENVIRON["HOME"] "/Documents/"
    ODSFILE = PATH "KevinJohnsonAviation_Business-Log.ods"
    MakeCsvCommandStr = "unoconv -f csv " ODSFILE
    if (1 - system(MakeCsvCommandStr)) {
        ARGV[1] = PATH "KevinJohnsonAviation_Business-Log.csv"
        ARGC = 2
        getline
        OutstandingBalancesExist=0
        OwesMe[""] = 0
    }
    else {
        print "ERROR converting ODF to CSV using unoconv"
    }
}

{
    date = $1
    customer = $2
    invoiced = $3
    paid = $4
    balance = $5
    supplier = $6
    expense = $7

    invoicesFormatStr = "    %13s  %16s  %15s\n"
    owesOnThisInvoice = gensub("[,$\"]", "", "g", balance)
    if ((customer != "") && (owesOnThisInvoice < 0)) {
        if (!OutstandingBalancesExist) {
            print "Outstanding Invoices Exist:"
            printf(invoicesFormatStr, "Date", "Customer", "Balance")
        }
        OutstandingBalancesExist=1
        printf(invoicesFormatStr, date, customer, balance)
        OwesMe[customer] = OwesMe[customer] - owesOnThisInvoice
    }
}

END{
    totalOutstanding = 0
    if (!OutstandingBalancesExist) {
        print "No outstanding balances on any customer accounts."
    }
    else {
        print "\nCustomers who owe me money:"
        for (customer in OwesMe) {
            if (customer != "") {
                printf("    %s owes $%'.2f\n", customer, OwesMe[customer])
                totalOutstanding = totalOutstanding + OwesMe[customer]
            }
        }
        printf("\nTotal Outstanding Invoices: $%'.2f\n", totalOutstanding)
    }
}
