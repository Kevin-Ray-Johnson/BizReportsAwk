#!/usr/bin/gawk -f

function repeatStrNtimes (Str, n) {
    retStr = ""
    for(i=0 ; i<n; i++ ) { retStr = retStr Str }
    return retStr
}

function spaces (n) { return repeatStrNtimes(" ", n) }

function byEntity (EventArray, totalStr, mult) {
    totalEvents = 0
    for (entity in EventArray) {
        if (entity != "") {
            printf("%s%20s: %10'.2f\n", \
                       spaces(10), entity, mult*EventArray[entity])
            totalEvents = totalEvents + EventArray[entity]
        }
    }
    printf("\n%s%17s: %10'.2f\n\n", spaces(29), totalStr, totalEvents * mult)
    return totalEvents * mult
}

function getDate (dateStr, formatStr) {
    cmd = "date " dateStr " +\"" formatStr "\""
    if ((cmd | getline returnDate) <= 0) {
        print "Can't get system date" > "/dev/stderr"
        exit 1
    }
    else {
        close(cmd)
        return returnDate
    }
}

BEGIN{
    FS = ","
    PATH = ENVIRON["HOME"] "/Documents/"
    ODSFILE = PATH "KevinJohnsonAviation_Business-Log.ods"
    if (1 - system( "unoconv -f csv " ODSFILE)) {
        ARGV[1] = PATH "KevinJohnsonAviation_Business-Log.csv"
        ARGC = 2
        getline # Loose the column header row.
        SalesToCustomers[""] = 0
        OwesMe[""] = 0
        ExpensesByVendor[""] = 0
        date_now = getDate("", "%e %b. %Y")
        startDateVal = 9**9**9  # approx. infinity
        lastDateVal = -startDateVal
    }
    else {
        print "ERROR converting ODF to CSV using unoconv"
        exit 1
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

    dateVal = getDate( "-d \"" date "\"", "%Y%j")
    if (dateVal > lastDateVal) {
        lastDateVal = dateVal
        lastDate = date
    }
    if (dateVal < startDateVal) {
        startDateVal = dateVal
        startDate = date
    }

    invoicedValue = gensub("[,$\"]", "", "g", invoiced)
    if ((customer != "") && (invoicedValue > 0)) {
        SalesToCustomers[customer] = SalesToCustomers[customer] + invoicedValue
        owesOnThisInvoice = gensub("[,$\"]", "", "g", balance)
        if (owesOnThisInvoice < 0) {
            OwesMe[customer] = OwesMe[customer] - owesOnThisInvoice
        }
    }

    expenseValue = gensub("[,$\"]", "", "g", expense)
    if ((supplier != "") && (expenseValue < 0)) {
        ExpensesByVendor[supplier] = ExpensesByVendor[supplier] + expenseValue
    }
}

END {
    print "BUSINESS SUMMARY:"
    print "Generated on " date_now
    print "Data from " startDate " to " lastDate "\n"
    print "    SALES REPORT:\n"
    print "          Invoices by customer:"
    totalSales = byEntity(SalesToCustomers, "Total Sales", 1)
    print "    COLLECTIONS REPORT:\n"
    print "       Collections by customer:"
    totalOutstanding = byEntity(OwesMe, "Total Collections", -1)
    print "    EXPENSES REPORT:\n"
    print "          Expenses by supplier:"
    totalExpenses = byEntity(ExpensesByVendor, "Total Expenses", 1)
    printf("%s%17s: %10'.2f\n\n", spaces(29), "NET PROFIT/LOSS", \
               totalSales + totalOutstanding + totalExpenses )
}
