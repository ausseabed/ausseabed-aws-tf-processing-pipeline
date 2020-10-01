import unittest
import time
from appium import webdriver


class CarisRunner(unittest.TestCase):

    @classmethod
    def setUpClass(self):
        # set up appium
        try:
            raise
            desired_caps = {}
            desired_caps["app"] = "C:\\Program Files\\CARIS\\HIPS and SIPS\\11.3\\bin\\caris_hips.exe"
            self.driver = webdriver.Remote(
                command_executor='http://13.239.27.189:4747',
                desired_capabilities=desired_caps)
        except:
            desired_caps = {}
            desired_caps["app"] = "Root"
            self.driver = webdriver.Remote(
                command_executor='http://13.239.27.189:4747',
                desired_capabilities=desired_caps)

    @classmethod
    def tearDownClass(self):
        self.driver.quit()

    def test_multiplication(self):
        caris_window = self.driver.find_element_by_name("CARIS HIPS and SIPS")
        #self.driver.find_element_by_name("Close").click()
        #menu_bar = caris_window.find_element_by_name("Menu bar")
        #menu_bar.click()
        menu2 = caris_window.find_elements_by_tag_name("MenuItem")
        menu2[0].click()
        caris_window.send_keys("x")
        # menu2 = menu_bar.find_elements()

        print("lol")



if __name__ == '__main__':
    suite = unittest.TestLoader().loadTestsFromTestCase(CarisRunner)
    unittest.TextTestRunner(verbosity=2).run(suite)
